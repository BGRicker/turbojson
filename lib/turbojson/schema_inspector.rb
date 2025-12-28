# frozen_string_literal: true

module Turbojson
  class SchemaInspector
    def self.column?(model_class, name)
      table = model_class.respond_to?(:table_name) ? model_class.table_name : nil

      if model_class.respond_to?(:connection)
        cache = model_class.connection.schema_cache if model_class.connection.respond_to?(:schema_cache)
        if cache && cache.respond_to?(:columns_hash) && table
          return cache.columns_hash(table).key?(name.to_s)
        end
      end

      if model_class.respond_to?(:columns_hash)
        return model_class.columns_hash.key?(name.to_s)
      end

      false
    end
  end
end
