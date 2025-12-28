# frozen_string_literal: true

require "spec_helper"

RSpec.describe "SQL snapshots" do
  FakeReflection = Struct.new(:klass, :foreign_key, :active_record)

  class SnapshotPhotoModel
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

  class SnapshotCategoryModel
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

  class SnapshotBarModel
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
        FakeReflection.new(SnapshotCategoryModel, "category_id", self)
      when :bar_photos
        FakeReflection.new(SnapshotPhotoModel, "bar_id", self)
      end
    end
  end

  class SnapshotCategorySerializer < Turbojson::Serializer
    model SnapshotCategoryModel
    attributes :id, :name
  end

  class SnapshotPhotoSerializer < Turbojson::Serializer
    model SnapshotPhotoModel
    attributes :id, :url
  end

  class SnapshotBarSerializer < Turbojson::Serializer
    model SnapshotBarModel
    attributes :id, :name
    has_one :category, serializer: SnapshotCategorySerializer
    has_many :bar_photos, serializer: SnapshotPhotoSerializer
  end

  it "matches the stored SQL snapshot" do
    sql = SnapshotBarSerializer.to_sql
    expected = File.read("spec/fixtures/sql/bar_serializer.sql").strip

    expect(sql).to eq(expected)
  end
end
