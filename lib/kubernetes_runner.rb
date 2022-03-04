# frozen_string_literal: true

require 'yaml'
require 'active_support/core_ext/hash/keys'

require_relative 'config'
require_relative 'helper'
require_relative 'influx'
require_relative 'graphite'

module PHPA
  class KubernetesRunner
    include Helper

    attr_reader :config

    def initialize(config_file)
      @config = Config.new(config_file)
    end

    def act
      perform_action(@config)
    end

    private

    def perform_action(config)
      result = { scaled: false, failed: false, cooldown: 0 }
      action = decide(config)
      controller_name = config.controller_name
      controller = config.controller
      log_txt "performing action: #{action} on #{controller}:#{controller_name}" if config.verbose
      scope = "--namespace=#{config.namespace}"
      min = config.min_replicas
      max = config.max_replicas
      current = current_replicas(controller_name, controller, scope)
      log_txt "current_replicas: #{current} on #{controller}:#{controller_name}" if config.verbose
      action = :no_current_replicas if current.blank?

      case action
      when :do_nothing
        # scale to number of current replicas aka do nothing
        scale_to = current
      when :scale_up
        scale_to = current + Config::SCALE_BY
      when :scale_down
        scale_to = current - Config::SCALE_BY
      when :no_current_replicas
        log_txt "Failed to get current replica count for #{controller} " \
          "#{controller_name}, doing nothing"
        result[:failed] = true
        return result
      when :unknown
        unless config.fallback_enabled
          log_txt "Action: #{action}, Not triggering fallback as "\
            "fallback is not enabled"
          scale_to = current
        end
        # we went to reach to fallback_replicas slowly
        scale_to = fallback_scale_to(current, config.fallback_replicas)
        log_txt "Action: #{action}, fallback to #{scale_to} replicas " \
          "for #{contoller} #{controller_name}"
      end

      return result if scale_to == current

      # scale to desired replicas if current is not equal to desired replicas
      msg = config.dry_run ? '(dry run)' : ''

      # scale_to can fall outside min and max range, correct it
      scale_to = correct_scale_to(current, min, max, scale_to)

      if can_scale?(min, max, scale_to)
        log_txt "scaling #{controller}:#{controller_name} to #{scale_to} replicas #{msg}"
        scale_it(controller_name, controller, scope, scale_to) unless config.dry_run
        result[:scaled] = true
        result[:cooldown] = config.action_cooldown
      else
        log_txt "Will not scale #{controller} #{controller_name} to #{scale_to} " \
          "replicas, current: #{current}, min: #{min}, max: #{max},  #{msg}"
      end
      return result
    end

    # if current replica count:
    # - is less then min, set it to min
    # - is more then max, set it to max
    # - otherwise it will return scale_to as it is
    def correct_scale_to(current, min, max, scale_to)
      if current < min
        log_txt "current replicas for #{config.controller} #{config.controller_name} " \
          "are less then min replicas, will scale to #{min} replicas"
        return min
      elsif current > max
        log_txt "current replicas for #{config.controller} #{config.controller_name} " \
          "are more then max replicas, will scale to #{max} replicas"
        return max
      else
        return scale_to
      end
    end

    def decide(config)
      threshold = config.metric_threshold
      margin = config.metric_margin
      metric_type = config.metric_type

      max = threshold + margin
      min = threshold - margin
      begin
        current = current_metric_value(config)
        if config.verbose
          log_txt "Metric: #{config.metric_name} current: #{current} for " \
            "#{config.controller} #{config.controller_name}"
        end
        metric_status = if (min..max).cover?(current)
                          :ok # metric is in threshold range
                        elsif current < min
                          :low
                        else
                          :high
                        end
      rescue MetricFetchFailed => e
        log_txt "Failed to fetch metric from metric_server: " \
          "#{config.adaptor} for #{config.controller} #{config.controller_name}"
        print_backtrace(e)
        metric_status = :unknown
      end
      return get_action(metric_type, metric_status)
    end

    # positive means if metrics value is great then threshold then it's good and
    # we should scale down
    # negative means if metrics value is great then threshold then it's bad and we should
    # scale up
    # if metric value falls under metricThreshold +/- metricMargin the do nothing
    def get_action(type, status)
      case "#{type}_#{status}"
      when 'positive_ok', 'negative_ok'
        action = :do_nothing
      when 'positive_low', 'negative_high'
        # for positive metrics low is bad, ex: puma_capacity
        # for negative metrics high is bad, ex: kafka_consumer_lag
        action = :scale_up
      when 'positive_high', 'negative_low'
        # for negative metrics low is good, ex: kafka_consumer_lag
        # for positive metrics high is good, ex: puma_capacity
        action = :scale_down
      else
        # type or status is unknown, set action to unknown
        action ||= :unknown
      end
      return action
    end

    def current_metric_value(config)
      sleep_dur = 1
      Config::METRIC_RETRY.times do
        server_class = metric_server_class(config.adaptor)
        server_config = config.server[config.adaptor]
        result = server_class.get_metric(server_config)
        return result if result.present?

        sleep_dur += Config::RETRY_SLEEP_INCREMENT
        log_txt "current_metric_value for '#{config.metric_name}' is sleeping for #{sleep_dur}s"
        sleep sleep_dur
      end
      # out of retries
      raise MetricFetchFailed
    end

    def fallback_scale_to(current, fallback)
      # if same, do nothing
      return current if current == fallback
      # if current is less then fallback, scale up
      return current + Config::SCALE_BY if current < fallback
      # if current is more then fallback, scale down
      return current - Config::SCALE_BY if current > fallback
    end
  end
end
