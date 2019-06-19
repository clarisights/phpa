# frozen_string_literal: true

require 'yaml'
require 'awesome_print'
require 'active_support/core_ext/hash/keys'

require_relative 'helper'

module PHPA
  class Config
    DEFAULT_INTERVAL = 300 # seconds
    DEFAULT_ACTION_COOLDOWN = 60 # seconds
    RETRY_SLEEP_INCREMENT = 2 # seconds
    METRIC_RETRY = 6 # number of retries for fetching metric
    REPLICA_RETRY = 6 # number of retries for fetching replica count

    LOCK_DIR = '/tmp/phpa'.freeze

    SCALE_BY = 1 # replicas to scale by (down or up)

    attr_accessor :version, :verbose, :dry_run, :action_cooldown, \
                  :deploy_name, :namespace, :adaptor, :server, \
                  :min_replicas, :max_replicas, :fallback_replicas, \
                  :metric_name, :metric_type, :metric_threshold, :metric_margin, \
                  :interval

    def initialize(file_path)
      config = YAML.load_file(file_path)
      # TODO: do config validation and print helpful error messages
      config.deep_symbolize_keys!

      if config[:kind].strip != 'PHPAConfig'
        raise InvalidConfig, "Provided config '#{file_path}' is not valid PHPA config"
      end

      @verbose = config[:verbose] == 'true' ? true : false
      @dry_run = config[:dryRun] == 'true' ? true : false
      action_cooldown = config[:actionCooldown] || DEFAULT_ACTION_COOLDOWN
      @action_cooldown = action_cooldown.to_i
      interval = config[:interval] || DEFAULT_INTERVAL
      @interval = interval.to_i
      @version = config[:version]

      @deploy_name = config[:deployment][:name]
      @namespace = config[:deployment][:namespace]

      @server = config[:metricServer]
      @adaptor = config[:metricServer][:adaptor].to_sym

      @min_replicas = config[:deployment][:minReplicas].to_i
      @max_replicas = config[:deployment][:maxReplicas].to_i
      @fallback_replicas = config[:deployment][:fallbackReplicas].to_i

      @metric_name = config[:metric][:name]
      @metric_type = config[:metric][:metricType].to_sym
      @metric_threshold = config[:metric][:metricThreshold].to_f
      @metric_margin = config[:metric][:metricMargin].to_f

      if @verbose
        puts "=== Config: #{file_path} ==="
        ap config
      end
    end
  end
end
