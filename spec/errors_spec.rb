# frozen_string_literal: true

require "rspec"

require_relative "../lib/influx.rb"
require_relative "../lib/kubernetes_runner.rb"
require_relative "../lib/errors.rb"
require_relative "../lib/helper.rb"
require_relative "../lib/cli.rb"

describe "errors" do
  include PHPA::Helper

  it "test that MetricFetchFailed exception is raised" do
    runner = PHPA::KubernetesRunner.new("spec/config_files/influx-config.yaml")
    config = runner.config.server[runner.config.adaptor]
    expect(InfluxDB::Client).to receive(:new).with(config[:database],
                                                   host: config[:host],
                                                   port: config[:port],
                                                   username: config[:username],
                                                   password: config[:password],
                                                   retry: 20).and_raise(StandardError)
    expect { PHPA::Influx.get_metric(config) }.to raise_error(PHPA::MetricFetchFailed)
  end

  it "test that UnknownAdaptor exception is raised" do
    expect { metric_server_class("xyz") }.to raise_error(PHPA::UnknownAdaptor)
  end

  it "test that InvalidConfig exception is raised when no config file is provided" do
    expect { PHPA::CLI.new(Shellwords.split("./phpa-cli")) }.to raise_error(PHPA::InvalidConfig)
  end

  it "test that InvalidConfig exception is raised when kind in config file is not PHPAConfig" do
    expect do
      PHPA::CLI.new(Shellwords.split("./phpa-cli spec/config_files/invalid-influx-config.yaml"))
    end.to raise_error(PHPA::InvalidConfig)
  end

  it "test that CommandFailed exception is raised when command execution fails" do
    expect { execute_command("kubectl sth") }.to raise_error(PHPA::CommandFailed)
  end
end
