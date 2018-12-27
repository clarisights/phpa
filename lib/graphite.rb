# frozen_string_literal: true

require 'httparty'
require_relative 'errors'
require_relative 'helper'

module PHPA
  class Graphite
    class << self
      include Helper

      def get_metric(config)
        host = config[:host]
        port = config[:port]
        query = config[:query]
        # https://graphite.readthedocs.io/en/latest/render_api.html
        uri = "http://#{host}:#{port}/render/?target=#{query}&format=json"
        response = HTTParty.get(uri)
        if response.code == 200
          data = response.parsed_response
          if data.size != 1
            msg = "Query returned more then one series, uri: #{uri}"
            raise MetricFetchFailed, msg
          end
          return data.first['datapoints'].last.first
        else
          raise "Failed to get metric: #{response.code}"
        end
      rescue StandardError => e
        # we retry on MetricFetchFailed, so always raise MetricFetchFailed
        raise_metric_fetch_failed(e)
      end
    end
  end
end
