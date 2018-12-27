# frozen_string_literal: true

require 'httparty'
require_relative 'errors'

module PHPA
  class Graphite
    def self.get_metric(config)
      host = config[:host]
      port = config[:port]
      query = config[:query]
      # https://graphite.readthedocs.io/en/latest/render_api.html
      # q can be retrieved from Grafana
      # FIXME: hostname works on pod but not when using VPN from local
      # host = 'graphite-server'
      # host = '10.132.0.5'
      # port = 8013
      # query = "target=summarize(production.kafka-lag.kafka-cluster-1.topics.*.production_*.lag, '1min', 'avg', false)&from=-5min&until=now&format=json"
      response = HTTParty.get("http://#{host}:#{port}/render/?#{query}")
      if response.code == 200
        return response.parsed_response.first['datapoints'].last.first
      else
        raise "Failed to get metric: #{response.code}"
      end
    rescue
      # we retry on MetricFetchFailed
      raise MetricFetchFailed
    end
  end
end
