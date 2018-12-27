# frozen_string_literal: true

require 'influxdb'
require 'influxdb/client'

module PHPA
  class Influx
    def self.get_metric(config)
      database = config[:database]
      host = config[:host]
      port = config[:port]
      username = config[:username]
      password = config[:password]
      query = config[:query]
      # FIXME: hostname works on pod but not when using VPN from local
      # database = 'server_stats'
      # host = 'monitoring-2'
      # host = '10.140.0.8'
      # port = 8086
      # FIXME: get these things from config
      # username = ''
      # password = ''
      # query = "SELECT mean(\"pool_capacity\") FROM \"puma\" WHERE (\"env\" = 'production') AND time >= now() - 2m GROUP BY time(10s)"
      client = InfluxDB::Client.new(
        database, host: host, port: port,  username: username, password: password
      )
      result = client.query(query)
      return result.first['values'].map(&:values).last.last
    rescue
      # we retry on MetricFetchFailed
      raise MetricFetchFailed
    end
  end
end
