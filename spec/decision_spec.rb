require 'rspec'

require_relative '../lib/kubernetes_runner.rb'

describe 'decision' do
  context 'when the metric is positive' do
    before(:each) do
      @runner = PHPA::KubernetesRunner.new('spec/config_files/influx-config.yaml')
      @config = @runner.config
    end

    it 'decision to scale down is taken when current metrics are more than threshold' do
      expect_any_instance_of(PHPA::KubernetesRunner).to receive(:current_metric_value)\
        .with(anything).and_return(25)
      action = @runner.send('decide', @config)
      expect(action).to eq(:scale_down)
    end

    it 'decision to do nothing is taken when current metrics is in allowed range' do
      expect_any_instance_of(PHPA::KubernetesRunner).to receive(:current_metric_value)\
        .with(anything).and_return(10)
      action = @runner.send('decide', @config)
      expect(action).to eq(:do_nothing)
    end

    it 'decision to scale up is taken when current metrics are more than the threshold' do
      expect_any_instance_of(PHPA::KubernetesRunner).to receive(:current_metric_value)\
        .with(anything).and_return(7)
      action = @runner.send('decide', @config)
      expect(action).to eq(:scale_up)
    end
  end

  context 'when the metric is negative' do
    before(:each) do
      @runner = PHPA::KubernetesRunner.new('spec/config_files/graphite-config.yaml')
      @config = @runner.config
    end

    it 'decision to scale up is taken when current metrics are more than threshold' do
      expect_any_instance_of(PHPA::KubernetesRunner).to receive(:current_metric_value)\
        .with(anything).and_return(50)
      action = @runner.send('decide', @config)
      expect(action).to eq(:scale_up)
    end

    it 'decision to do nothing is taken when the current metric is in allowed range' do
      expect_any_instance_of(PHPA::KubernetesRunner).to receive(:current_metric_value)\
        .with(anything).and_return(30)
      action = @runner.send('decide', @config)
      expect(action).to eq(:do_nothing)
    end

    it 'decision to scale up is taken when the current metric is less than the threshold' do
      expect_any_instance_of(PHPA::KubernetesRunner).to receive(:current_metric_value)\
        .with(anything).and_return(5)
      action = @runner.send('decide', @config)
      expect(action).to eq(:scale_down)
    end
  end
end
