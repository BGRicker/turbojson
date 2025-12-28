# frozen_string_literal: true

module Turbojson
  class PostProcessor
    def self.process(payload, key_suffix: "_key", &block)
      case payload
      when Array
        payload.map { |item| process(item, key_suffix: key_suffix, &block) }
      when Hash
        payload.each_with_object({}) do |(key, value), acc|
          acc[key] = transform_value(key, value, key_suffix, &block)
        end
      else
        payload
      end
    end

    def self.transform_value(key, value, key_suffix, &block)
      if key.to_s.end_with?(key_suffix) && block
        block.call(value)
      else
        process(value, key_suffix: key_suffix, &block)
      end
    end
  end
end
