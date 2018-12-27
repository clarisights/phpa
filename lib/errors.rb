module PHPA
  class MetricFetchFailed < StandardError
    def initialize(msg = "Failed to get metric from endpoint")
      super
    end
  end

  class UnknownAdaptor < StandardError
    def initialize(adaptor_name)
      super("Unknown Matric Adaptor: #{adaptor_name}")
    end
  end
end