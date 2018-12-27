#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash/keys'
require 'yaml'
require 'awesome_print'

class Deploy
  CLUSTER_CONFIG = 'clusters.yaml'.freeze

  def initialize(args)
    options = {}
    option_parser = init_option_parser(options)
    # Parse the command-line. Remember there are two forms
    # of the parse method. The 'parse' method simply parses
    # args, while the 'parse!' method parses args and removes
    # any options found there, as well as any parameters for
    # the options.
    option_parser.parse!(args)
    process(options)
  end

  def process(options)
    if options[:all]
      # deploy to all clusters
      deploy_all
    else
      # deploy to single context
      context = options[:context]
      # select current-context if no context is passed
      context = `kubectl config current-context`.strip if context.blank?
      cluster = context.split('_').last
      image_info = build_and_push_image
      deploy_autoscaler(cluster, context, image_info)
    end
  end

  private

  def deploy_all
    image_info = build_and_push_image

    clusters = YAML.load_file(CLUSTER_CONFIG)
    clusters.deep_symbolize_keys!
    clusters[:clusters].each do |config|
      context = config[:context]
      cluster = context.split('_').last
      if config[:enabled]
        deploy_autoscaler(cluster, context, image_info)
      else
        delete_autoscaler(cluster, context)
      end
    end
  end

  def deploy_autoscaler(cluster, context, image_info)
    image = image_info[:image]
    ts = image_info[:timestamp_tag]
    scope = "--context=#{context}"

    puts 'Deploying autoscaler on...'
    puts "Cluster: #{cluster}"
    puts "Context: #{context}"
    puts "Image: #{image}:#{ts}"

    # check for `phpa-service-account`
    # NOTE: we need phpa-service-account, if not found create it using
    # 'kubectl apply -f setup-access.yaml'
    exec("kubectl get serviceaccount phpa-service-account #{scope}")

    # deploy autoscaler
    exec("kubectl apply -f deploy/#{cluster}-autoscaler.yaml #{scope}")
    exec("kubectl set image deployment #{cluster}-autoscaler phpa=#{image}:#{ts} --record #{scope}")

    # check deployment status
    exec("kubectl rollout status deployments #{cluster}-autoscaler #{scope}")
  end

  def delete_autoscaler(cluster, context)
    scope = "--context=#{context}"
    puts 'Cleanup autoscaler on...'
    puts "Cluster: #{cluster}"
    puts "Context: #{context}"

    exec("kubectl delete -f deploy/#{cluster}-autoscaler.yaml #{scope} || true")
  end

  # build, tag and push image to gcr
  def build_and_push_image
    epoch = Time.now.utc.to_i
    image = 'gcr.io/flowing-bazaar-726/phpa'.freeze
    puts "Building docker image: #{image}"

    exec('docker build -t phpa:latest .')
    exec("docker tag phpa #{image}:#{epoch}")
    exec("docker push #{image}:#{epoch}")
    exec("gcloud container images add-tag --quiet #{image}:#{epoch} #{image}:latest")
    return { image: image, timestamp_tag: epoch }
  end

  def exec(command)
    system(command)
    result = $?
    return if result.exitstatus.zero?

    # fail if command exits with non-zero exit code
    puts result
    puts "Exit status code: #{result.exitstatus}"
    raise "Failed to run command: '#{command}'"
  end

  # ============= CLI Option Parsing ==============

  def init_option_parser(options)
    option_parser = OptionParser.new do |parser|
      # Set a banner displayed at top of help screen
      parser.banner = 'USAGE: deploy-autoscaler [options]'
      parser.separator 'example: ./deploy.rb -c context'
      parser.separator 'If context is not passed it will deploy in current context'

      context_option(parser, options)
      all_option(parser, options)
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

  def all_option(parser, options)
    options[:all] = false
    help = "Deploy on all clusters defined in #{CLUSTER_CONFIG}"
    parser.on('--all', help) do
      options[:all] = true
    end
  end

  def context_option(parser, options)
    help = 'Deploy in a specific context'
    parser.on('-c', '--context CONTEXT', help) do |context|
      options[:context] = context
    end
  end
end

Deploy.new(ARGV)
