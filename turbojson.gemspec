# frozen_string_literal: true

require_relative "lib/turbojson/version"

Gem::Specification.new do |spec|
  spec.name = "turbojson"
  spec.version = Turbojson::VERSION
  spec.authors = ["Turbojson Contributors"]
  spec.summary = "Compile serializer DSL into Postgres JSON SQL"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.files = Dir["lib/**/*", "README*", "LICENSE*"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rspec", "~> 3.12"
end
