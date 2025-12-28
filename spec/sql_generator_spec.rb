# frozen_string_literal: true

require "spec_helper"

RSpec.describe Turbojson::SqlGenerator do
  FakeReflection = Struct.new(:klass, :foreign_key, :active_record)

  class PhotoModel
    def self.table_name
      "bar_photos"
    end

    def self.columns_hash
      {
        "id" => double("Column"),
        "bar_id" => double("Column"),
        "url" => double("Column")
      }
    end
  end

  class CategoryModel
    def self.table_name
      "categories"
    end

    def self.columns_hash
      {
        "id" => double("Column"),
        "name" => double("Column")
      }
    end
  end

  class BarModel
    def self.table_name
      "bars"
    end

    def self.primary_key
      "id"
    end

    def self.columns_hash
      {
        "id" => double("Column"),
        "name" => double("Column"),
        "category_id" => double("Column")
      }
    end

    def self.reflect_on_association(name)
      case name
      when :category
        FakeReflection.new(CategoryModel, "category_id", self)
      when :bar_photos
        FakeReflection.new(PhotoModel, "bar_id", self)
      end
    end
  end

  class CategorySerializer < Turbojson::Serializer
    model CategoryModel
    attributes :id, :name
  end

  class PhotoSerializer < Turbojson::Serializer
    model PhotoModel
    attributes :id, :url
  end

  class BarSerializer < Turbojson::Serializer
    model BarModel
    attributes :id, :name
    has_one :category, serializer: CategorySerializer
    has_many :bar_photos, serializer: PhotoSerializer
  end

  it "builds SQL with json_build_object and lateral joins" do
    sql = described_class.new(BarSerializer.ast).to_sql

    expect(sql).to include("json_build_object('id', bars.id, 'name', bars.name")
    expect(sql).to include("LEFT JOIN LATERAL")
    expect(sql).to include("json_agg")
    expect(sql).to include("bar_photos_json.bar_photos")
  end
end
