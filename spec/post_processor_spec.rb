# frozen_string_literal: true

require "spec_helper"

RSpec.describe Turbojson::PostProcessor do
  it "transforms key-suffixed fields with the provided block" do
    payload = {
      "profile_picture_key" => "abc123",
      "nested" => {
        "avatar_key" => "xyz789"
      },
      "items" => [
        { "photo_key" => "k1" },
        { "photo_key" => "k2" }
      ]
    }

    result = described_class.process(payload) { |key| "signed/#{key}" }

    expect(result["profile_picture_key"]).to eq("signed/abc123")
    expect(result["nested"]["avatar_key"]).to eq("signed/xyz789")
    expect(result["items"][0]["photo_key"]).to eq("signed/k1")
  end

  it "leaves non-matching values unchanged" do
    payload = { "name" => "Bar", "count" => 2 }

    result = described_class.process(payload) { |key| "signed/#{key}" }

    expect(result).to eq(payload)
  end
end
