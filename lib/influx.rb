# frozen_string_literal: true

require 'influxdb'
require 'influxdb/client'
require_relative 'helper'

module PHPA
  class Influx
    class << self
      include Helper

      def get_metric(config)
        database = config[:database]
        host = config[:host]
        port = config[:port]
        username = config[:username]
        password = config[:password]
        query = config[:query]
        client = InfluxDB::Client.new(
          database,
          host: host,
          port: port,
          username: username,
          password: password,
          retry: 20
        )
        result = client.query(query)
        return result.first['values'].map(&:values).last.last
      rescue StandardError => e
        # we retry on MetricFetchFailed, so always raise MetricFetchFailed
        raise_metric_fetch_failed(e)
      end
    end
  end
end
