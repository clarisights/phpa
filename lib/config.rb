# frozen_string_literal: true

require 'yaml'
require 'awesome_print'
require 'active_support/core_ext/hash/keys'

require_relative 'helper'

module PHPA
  class Config
    SUPPORTED_CONTROLLERS = %i[deployment replicaset statefulset].freeze
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
                  :interval, :fallback_enabled, :controller, :controller_name

    def initialize(file_path)
      config = YAML.load_file(file_path)
      # TODO: do config validation and print helpful error messages
      config.deep_symbolize_keys!

      if config[:kind].strip != 'PHPAConfig'
        raise InvalidConfig, "Provided config '#{file_path}' is not valid PHPA config"
      end

      @verbose = config[:verbose] == 'true' ? true : false
      @dry_run = config[:dryRun] == 'true' ? true : false
      @fallback_enabled = config[:fallbackEnabled] == 'false' ? false : true
      action_cooldown = config[:actionCooldown] || DEFAULT_ACTION_COOLDOWN
      @action_cooldown = action_cooldown.to_i
      interval = config[:interval] || DEFAULT_INTERVAL
      @interval = interval.to_i
      @version = config[:version]
      @server = config[:metricServer]
      @adaptor = config[:metricServer][:adaptor].to_sym

      controllers = SUPPORTED_CONTROLLERS & config.keys
      # TODO: the wording could be better ?
      if controllers.count > 1
        raise InvalidConfig,
              "We currently support only one controller per config. We observe #{controllers.join('&')}"
      elsif controllers.count < 1
        raise InvalidConfig,
              "We expect exactly one controller per config. Found None."
      end
      @controller = controllers.first
      @controller_name = config[@controller][:name]
      # Deprecation Warning.
      @deploy_name = @controller_name if @controller == :deployment
      @namespace = config[@controller][:namespace]
      @min_replicas = config[@controller][:minReplicas].to_i
      @max_replicas = config[@controller][:maxReplicas].to_i
      @fallback_replicas = config[@controller][:fallbackReplicas].to_i

      @metric_name = config[:metric][:name]
      @metric_type = config[:metric][:metricType].to_sym
      @metric_threshold = config[:metric][:metricThreshold].to_f
      @metric_margin = config[:metric][:metricMargin].to_f

      if @verbose
        # Use a logger instead
        puts "=== Config: #{file_path} ==="
        ap config
      end
    end
  end
end
