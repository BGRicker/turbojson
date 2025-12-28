# frozen_string_literal: true

require_relative "ast"

module Turbojson
  class SqlGenerator
    AssociationInfo = Struct.new(:name, :table_name, :foreign_key, :parent_key)

    def initialize(ast)
      @ast = ast
    end

    def to_sql
      table_name = @ast.table_name
      object_sql, joins = build_json_object(@ast, table_name)

      sql = []
      sql << "SELECT #{object_sql} AS data"
      sql << "FROM #{table_name}"
      sql.concat(joins) unless joins.empty?
      sql.join("\n")
    end

    def select_parts
      build_json_object(@ast, @ast.table_name)
    end

    private

    def build_json_object(ast, table_alias)
      select_pairs = []
      joins = []

      ast.nodes.each do |node|
        case node
        when Ast::Attribute
          value = node.sql || "#{table_alias}.#{node.name}"
          select_pairs << "'#{node.name}', #{value}"
        when Ast::Association
          assoc = resolve_association(ast.model, node)
          child_ast = node.serializer_class.ast
          lateral_alias = "#{assoc.name}_json"

          subquery = if node.type == :has_many
                       build_has_many_subquery(child_ast, assoc, table_alias)
                     else
                       build_has_one_subquery(child_ast, assoc, table_alias)
                     end

          joins << "LEFT JOIN LATERAL (#{subquery}) #{lateral_alias} ON TRUE"
          select_pairs << "'#{node.name}', #{lateral_alias}.#{node.name}"
        end
      end

      ["json_build_object(#{select_pairs.join(', ')})", joins]
    end

    def build_has_one_subquery(child_ast, assoc, parent_table)
      object_sql, child_joins = build_json_object(child_ast, assoc.table_name)
      sql = []
      sql << "SELECT #{object_sql} AS #{assoc.name}"
      sql << "FROM #{assoc.table_name}"
      sql.concat(child_joins) unless child_joins.empty?
      sql << "WHERE #{assoc.table_name}.#{assoc.foreign_key} = #{parent_table}.#{assoc.parent_key}"
      sql << "LIMIT 1"
      sql.join("\n")
    end

    def build_has_many_subquery(child_ast, assoc, parent_table)
      object_sql, child_joins = build_json_object(child_ast, assoc.table_name)
      inner = []
      inner << "SELECT #{object_sql} AS data"
      inner << "FROM #{assoc.table_name}"
      inner.concat(child_joins) unless child_joins.empty?
      inner << "WHERE #{assoc.table_name}.#{assoc.foreign_key} = #{parent_table}.#{assoc.parent_key}"

      sql = []
      sql << "SELECT COALESCE(json_agg(child_rows.data), '[]'::json) AS #{assoc.name}"
      sql << "FROM (#{inner.join("\n")}) child_rows"
      sql.join("\n")
    end

    def resolve_association(model, node)
      reflection = model.respond_to?(:reflect_on_association) ? model.reflect_on_association(node.name) : nil
      raise ConfigurationError, "Association #{node.name} not found for #{model}" unless reflection

      table_name = reflection.klass.table_name
      foreign_key = reflection.foreign_key
      parent_key = model.respond_to?(:primary_key) ? model.primary_key : "id"

      AssociationInfo.new(node.name, table_name, foreign_key, parent_key)
    end
  end
end
