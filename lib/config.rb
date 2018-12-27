# frozen_string_literal: true

require 'yaml'
require 'active_support/core_ext/hash/keys'
require_relative 'helper'

module PHPA
  class Config
    # DEFAULT_CONFIG_OPTIONS maps (most) of the configuration options to
    # their default value. They can be changed at runtime
    # through the PHPA::Client instance.
    DEFAULT_CONFIG_OPTIONS = {}.freeze

    class << self
      def load(file_path)
        config = YAML.load_file(file_path)
        # TODO: do config validation and stuff and return Config object
        config.deep_symbolize_keys!
      end
    end
  end
end