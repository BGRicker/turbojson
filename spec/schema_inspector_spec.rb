# frozen_string_literal: true

require "spec_helper"

RSpec.describe Turbojson::SchemaInspector do
  class CacheModel
    def self.table_name
      "bars"
    end

    def self.connection
      @connection ||= begin
        cache = Class.new do
          def columns_hash(table)
            return {} unless table == "bars"

            { "id" => double("Column"), "name" => double("Column") }
          end
        end.new

        Class.new do
          define_method(:schema_cache) { cache }
        end.new
      end
    end
  end

  class ColumnsHashModel
    def self.table_name
      "bars"
    end

    def self.columns_hash
      { "id" => double("Column") }
    end
  end

  it "uses schema_cache when available" do
    expect(described_class.column?(CacheModel, :name)).to eq(true)
    expect(described_class.column?(CacheModel, :missing)).to eq(false)
  end

  it "falls back to columns_hash when schema_cache is absent" do
    expect(described_class.column?(ColumnsHashModel, :id)).to eq(true)
    expect(described_class.column?(ColumnsHashModel, :name)).to eq(false)
  end
end
