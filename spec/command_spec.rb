require 'rspec'

require_relative '../lib/cli'
require_relative '../lib/kubernetes_runner'

describe 'command' do
  context 'When statefulsets are used' do
    before(:each) do
      @controller = PHPA::Config::SUPPORTED_CONTROLLERS.sample
      @runner = PHPA::KubernetesRunner.new("spec/config_files/#{@controller}.yaml")
      @config = @runner.config
    end

    it 'generates the correct commands' do
      # scale up
      current_replicas_mock = double(YAML)
      current_replicas_response = { 'status' => { 'replicas' => 1 } }
      allow(@runner).to receive(:current_metric_value).and_return(80)
      expect(@runner).to receive(:execute_command).with(
        "kubectl get #{@controller} query-db -o yaml --namespace=query-db", verbose: false
      ).and_return(current_replicas_mock)
      allow(YAML).to receive(:load).with(current_replicas_mock).and_return(current_replicas_response)
      expect(@runner).to receive(:execute_command).with("kubectl scale #{@controller} query-db --replicas=2 --namespace=query-db")
      @runner.act

      # do nothing
      current_replicas_response = { 'status' => { 'replicas' => 2 } }
      allow(@runner).to receive(:current_metric_value).and_return(55)
      expect(@runner).to receive(:execute_command).with(
        "kubectl get #{@controller} query-db -o yaml --namespace=query-db", verbose: false
      ).and_return(current_replicas_mock)
      allow(YAML).to receive(:load).with(current_replicas_mock).and_return(current_replicas_response)
      expect(@runner).not_to receive(:execute_command).with("kubectl scale #{@controller} query-db --replicas=3 --namespace=query-db")
      @runner.act

      # scale down
      current_replicas_response = { 'status' => { 'replicas' => 2 } }
      allow(@runner).to receive(:current_metric_value).and_return(10)
      expect(@runner).to receive(:execute_command).with(
        "kubectl get #{@controller} query-db -o yaml --namespace=query-db", verbose: false
      ).and_return(current_replicas_mock)
      allow(YAML).to receive(:load).with(current_replicas_mock).and_return(current_replicas_response)
      expect(@runner).not_to receive(:execute_command).with("kubectl scale #{@controller} query-db --replicas=2 --namespace=query-db")
      @runner.act
    end
  end
end
