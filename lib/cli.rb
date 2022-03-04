# frozen_string_literal: true

require 'optparse'
require 'parallel'
require 'active_support/core_ext/object/blank'

require_relative 'kubernetes_runner'
require_relative 'helper'

module PHPA
  class CLI
    include Helper

    BOOT_SLEEP_TIME = 120  # seconds

    def initialize(args)
      options = {}
      option_parser = init_option_parser(options)
      # Parse the command-line. Remember there are two forms
      # of the parse method. The 'parse' method simply parses
      # args, while the 'parse!' method parses args and removes
      # any options found there, as well as any parameters for
      # the options.
      option_parser.parse!(args)
      gracefully_shutdown if options[:quit]

      config_file = options[:config_file]
      if config_file.blank?
        config_path = ENV['PHPA_CONFIG_PATH'].to_s.strip
        if config_path.blank?
          raise InvalidConfig, "No config_path or config_file provided"
        end
        process_path(config_path)
      else
        runner = runner(config_file)
        puts runner.act
      end
    end

    private

    def process_path(config_path)
      log_txt "Running in cluster mode, config_path: #{config_path}"
      path = File.expand_path(config_path, File.dirname(__FILE__))
      config_files = Dir[path].sort

      # build runners from config files and keep looping over them
      runners = runners(config_files)
      # we need to sleep on boot because sometimes autoscaler(PHPA) will scale down
      # a controller, and after that autoscaler(PHPA) will be the only pod running
      # so k8s will relocate autoscaler(PHPA) to scale down node pool
      log_txt "Sleeping on boot for #{BOOT_SLEEP_TIME} seconds..."
      sleep BOOT_SLEEP_TIME
      Parallel.each(runners) do |runner|
        loop do
          controller_name = runner.config.controller_name
          controller = runner.config.controller
          interval = runner.config.interval
          acquire_lock(controller_name, controller)
          result = runner.act
          release_lock(controller_name, controller)
          cooldown = result[:cooldown]
          log_txt "#{controller_name} #{controller} cooldown: sleeping " \
            "for #{cooldown} seconds"
          log_txt "#{controller_name} #{controller} Sleeping for #{interval} seconds"
          sleep interval + cooldown
        end
      end
    end

    def runners(config_files)
      runners = []
      config_files.each do |config_file|
        runners << runner(config_file)
      end
      puts ''
      return runners
    end

    def runner(config_file)
      log_txt "Loading config from: #{config_file}"
      KubernetesRunner.new(config_file)
    end

    def init_option_parser(options)
      option_parser = OptionParser.new do |parser|
        # Set a banner displayed at top of help screen
        parser.banner = "USAGE: phpa-cli [options]"
        parser.separator "phpa-cli -f config.yml"
        parser.separator ""
        config_file_option(parser, options)
        quit_option(parser, options)
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
      parser.on('-f', '--config-file FILEPATH', 'specify config file to load') do |config_file|
        options[:config_file] = config_file
      end
    end

    def quit_option(parser, options)
      options[:quit] = false
      parser.on('--quit', 'Check if PHPA can shutdown') do
        options[:quit] = true
      end
    end
  end
end
