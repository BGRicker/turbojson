# frozen_string_literal: true

require "json"
require "ostruct"
require_relative "ast"
require_relative "schema_inspector"

module Turbojson
  class ConfigurationError < Error; end

  class Serializer
    class << self
      def model(klass = nil)
        if klass
          config[:model] = klass
        else
          config[:model]
        end
      end

      def attributes(*names, &block)
        raise ArgumentError, "attributes requires at least one name" if names.empty?

        names.each do |name|
          config[:attributes] << {
            name: name.to_sym,
            sql: block&.call(model_scope)
          }
        end
      end

      def has_one(name, serializer:)
        config[:associations] << {
          name: name.to_sym,
          type: :has_one,
          serializer: serializer
        }
      end

      def has_many(name, serializer:)
        config[:associations] << {
          name: name.to_sym,
          type: :has_many,
          serializer: serializer
        }
      end

      def ast
        model_class = config[:model]
        raise ConfigurationError, "Serializer missing model" unless model_class

        table_name = infer_table_name(model_class)
        nodes = []

        config[:attributes].each do |attr|
          validate_column!(model_class, attr[:name]) if attr[:sql].nil?
          nodes << Ast::Attribute.new(name: attr[:name], sql: attr[:sql])
        end

        config[:associations].each do |assoc|
          nodes << Ast::Association.new(
            name: assoc[:name],
            type: assoc[:type],
            serializer_class: assoc[:serializer]
          )
        end

        Ast::Root.new(model: model_class, table_name: table_name, nodes: nodes)
      end

      def to_sql
        SqlGenerator.new(ast).to_sql
      end

      def serialize(scope)
        raise ArgumentError, "scope is required" if scope.nil?
        raise ConfigurationError, "Arel is required to build SQL" unless defined?(Arel)

        generator = SqlGenerator.new(ast)
        object_sql, joins = generator.select_parts

        unless scope.respond_to?(:select) && scope.respond_to?(:joins) && scope.respond_to?(:to_sql)
          raise ConfigurationError, "serialize expects an ActiveRecord::Relation-like scope"
        end

        relation = scope.select(Arel.sql("#{object_sql} AS data"))
        joins.each do |join_sql|
          relation = relation.joins(Arel.sql(join_sql))
        end

        sql = <<~SQL
          SELECT COALESCE(json_agg(rows.data), '[]'::json) AS data
          FROM (#{relation.to_sql}) rows
        SQL

        connection = scope.connection
        result = connection.select_value(sql)

        return result unless result.is_a?(String)

        JSON.parse(result)
      end

      def model_scope
        model_class = config[:model]
        return nil unless model_class

        if model_class.respond_to?(:table_name)
          OpenStruct.new(table_name: model_class.table_name)
        else
          nil
        end
      end

      private

      def config
        @config ||= begin
          parent = superclass.respond_to?(:config) ? superclass.send(:config) : {}
          {
            model: parent[:model],
            attributes: Array(parent[:attributes]).dup,
            associations: Array(parent[:associations]).dup
          }
        end
      end

      def infer_table_name(model_class)
        return model_class.table_name if model_class.respond_to?(:table_name)

        raise ConfigurationError, "Model must respond to table_name"
      end

      def validate_column!(model_class, name)
        unless SchemaInspector.column?(model_class, name)
          raise ConfigurationError, "Unknown column #{name} for #{model_class}"
        end
      end
    end
  end
end
