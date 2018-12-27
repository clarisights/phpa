# frozen_string_literal: true

require 'optparse'
require 'active_support/core_ext/object/blank'
require 'awesome_print'
require 'byebug'

require_relative 'config'
require_relative 'influx'
require_relative 'graphite'
require_relative 'helper'

module PHPA
  class CLI
    include Helper
    REQUIRED_ARGS = [:config_file].freeze

    def initialize(args)
      options = {}
      option_parser = init_option_parser(options)
      # Parse the command-line. Remember there are two forms
      # of the parse method. The 'parse' method simply parses
      # args, while the 'parse!' method parses args and removes
      # any options found there, as well as any parameters for
      # the options.
      option_parser.parse!(args)

      REQUIRED_ARGS.each do |arg|
         raise "#{arg} is required" if options[arg].blank?
      end

      process(options)
    end

    private

    def process(options)
      ap options
      config = PHPA::Config.load(options[:config_file])
      adaptor = config[:metric_server][:adaptor]
      metric_server_klass = metric_server_class(adaptor)
      ap metric_server_klass
      metric_server_config = config[:metric_server][adaptor.to_sym]
      ap metric_server_klass.get_metric(metric_server_config)
      ap PHPA::Influx.get_metric(config[:metric_server][:influxdb])
      ap PHPA::Graphite.get_metric(config[:metric_server][:graphite])
    end

    def init_option_parser(options)
      option_parser = OptionParser.new do |parser|
        # Set a banner displayed at top of help screen
        parser.banner = "USAGE: phpa-cli [options]"
        parser.separator "phpa-cli -f config.yml"
        parser.separator ""
        config_file_option(parser, options)
        help_option(parser)
      end
      return option_parser
    end

    # option definition
    def help_option(parser)
      parser.on('-h', '--help', 'Display this screen') do
        puts parser
        exit
      end
    end

    def config_file_option(parser, options)
      parser.on('-f', '--file FILEPATH', 'specify config file to load') do |filter|
        options[:config_file] = filter
      end
    end
  end
end
