# frozen_string_literal: true

require "spec_helper"

RSpec.describe "ActiveModel::Serializer parity" do
  it "matches ActiveModel::Serializer output when dependencies are available" do
    unless defined?(ActiveModel::Serializer)
      skip "ActiveModel::Serializer not available; add it to development dependencies to enable this spec"
    end

    skip "TODO: Implement once serialize(scope) is wired to ActiveRecord"
  end
end
