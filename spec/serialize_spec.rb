# frozen_string_literal: true

require "spec_helper"

module Arel
  def self.sql(value)
    value
  end
end

RSpec.describe Turbojson::Serializer do
  class SerializeModel
    def self.table_name
      "bars"
    end

    def self.columns_hash
      { "id" => double("Column") }
    end
  end

  class SerializeSerializer < Turbojson::Serializer
    model SerializeModel
    attributes :id
  end

  class FakeConnection
    attr_reader :last_sql

    def initialize(result)
      @result = result
    end

    def select_value(sql)
      @last_sql = sql
      @result
    end
  end

  class FakeRelation
    attr_reader :connection, :selects, :joins

    def initialize(connection)
      @connection = connection
      @selects = []
      @joins = []
    end

    def select(value)
      @selects << value
      self
    end

    def joins(value)
      @joins << value
      self
    end

    def to_sql
      "SELECT 1 AS data"
    end
  end

  it "returns parsed JSON from the aggregated SQL" do
    connection = FakeConnection.new("[{\"id\":1}]")
    scope = FakeRelation.new(connection)

    result = SerializeSerializer.serialize(scope)

    expect(result).to eq([{ "id" => 1 }])
    expect(connection.last_sql).to include("json_agg")
  end
end
