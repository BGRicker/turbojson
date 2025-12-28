# frozen_string_literal: true

module Turbojson
  module Ast
    class Root
      attr_reader :model, :table_name, :nodes

      def initialize(model:, table_name:, nodes:)
        @model = model
        @table_name = table_name
        @nodes = nodes
      end
    end

    class Attribute
      attr_reader :name, :sql

      def initialize(name:, sql: nil)
        @name = name
        @sql = sql
      end
    end

    class Association
      attr_reader :name, :type, :serializer_class

      def initialize(name:, type:, serializer_class:)
        @name = name
        @type = type
        @serializer_class = serializer_class
      end
    end
  end
end
