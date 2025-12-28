# frozen_string_literal: true

require "spec_helper"

RSpec.describe Turbojson::Serializer do
  class DummyModel
    def self.table_name
      "bars"
    end

    def self.columns_hash
      {
        "id" => double("Column"),
        "name" => double("Column")
      }
    end
  end

  class DummySerializer < Turbojson::Serializer
    model DummyModel
    attributes :id, :name
  end

  it "builds an AST with validated attributes" do
    ast = DummySerializer.ast

    expect(ast.table_name).to eq("bars")
    expect(ast.nodes.map(&:class)).to include(Turbojson::Ast::Attribute)
  end

  it "raises when attributes are not model columns" do
    klass = Class.new(Turbojson::Serializer) do
      model DummyModel
      attributes :missing
    end

    expect { klass.ast }.to raise_error(Turbojson::ConfigurationError)
  end

  it "records associations in the AST" do
    assoc_serializer = Class.new(Turbojson::Serializer) do
      model DummyModel
      attributes :id
    end

    klass = Class.new(Turbojson::Serializer) do
      model DummyModel
      has_many :bars, serializer: assoc_serializer
    end

    ast = klass.ast

    association = ast.nodes.detect { |node| node.is_a?(Turbojson::Ast::Association) }
    expect(association.type).to eq(:has_many)
    expect(association.serializer_class).to eq(assoc_serializer)
  end
end
