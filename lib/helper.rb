module PHPA
  module Helper
    def metric_server_class(adaptor_name)
      case adaptor_name
      when 'graphite'
        return PHPA::Graphite
      when 'influxdb'
        return PHPA::Influx
      else
        raise UnknownAdaptor, adaptor_name
      end
    end
  end
end