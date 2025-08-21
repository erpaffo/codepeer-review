require 'rails_helper'

RSpec.describe Kube::JobRunner do
  before do
    allow(Rails.configuration.x.k8s).to receive(:enabled).and_return(true)
    allow(Rails.configuration.x.k8s).to receive(:namespace).and_return('default')
    allow(Rails.configuration.x.k8s).to receive(:job_active_deadline_seconds).and_return(10)
    allow(Rails.configuration.x.k8s).to receive(:job_cpu_limit).and_return('500m')
    allow(Rails.configuration.x.k8s).to receive(:job_memory_limit).and_return('256Mi')
    allow(Rails.configuration.x.k8s).to receive(:image_pull_policy).and_return('IfNotPresent')
  end

  it 'crea Job, attende il Pod e restituisce i log con status di successo' do
    # kubectl apply
    expect(Open3).to receive(:capture3)
      .with('kubectl', 'apply', '-f', '-', '-n', 'default', anything)
      .and_return(["job.batch/ok created\n", '', instance_double(Process::Status, success?: true)])

    # get pod name polling (first empty, then ready)
    expect(Open3).to receive(:capture3)
      .with('kubectl', 'get', 'pods', '-n', 'default', '-l', kind_of(String), '-o', 'jsonpath={.items[0].metadata.name}')
      .and_return(['', '', instance_double(Process::Status, success?: true)])
    expect(Open3).to receive(:capture3)
      .with('kubectl', 'get', 'pods', '-n', 'default', '-l', kind_of(String), '-o', 'jsonpath={.items[0].metadata.name}')
      .and_return(['pod-abc', '', instance_double(Process::Status, success?: true)])

    # get pod phase (first Running, then Succeeded)
    expect(Open3).to receive(:capture3)
      .with('kubectl', 'get', 'pod', 'pod-abc', '-n', 'default', '-o', 'jsonpath={.status.phase}')
      .and_return(['Running', '', instance_double(Process::Status, success?: true)])
    expect(Open3).to receive(:capture3)
      .with('kubectl', 'get', 'pod', 'pod-abc', '-n', 'default', '-o', 'jsonpath={.status.phase}')
      .and_return(['Succeeded', '', instance_double(Process::Status, success?: true)])

    # logs
    expect(Open3).to receive(:capture3)
      .with('kubectl', 'logs', 'pod-abc', '-n', 'default')
      .and_return(["hi\n", '', instance_double(Process::Status, success?: true)])

    # exit code
    expect(Open3).to receive(:capture3)
      .with('kubectl', 'get', 'pod', 'pod-abc', '-n', 'default', '-o', 'jsonpath={.status.containerStatuses[0].state.terminated.exitCode}')
      .and_return(['0', '', instance_double(Process::Status, success?: true)])

    # cleanup
    expect(Open3).to receive(:capture3)
      .with('kubectl', 'delete', 'job', kind_of(String), '-n', 'default', '--ignore-not-found=true')
      .and_return(['', '', instance_double(Process::Status, success?: true)])

    out, err, status = described_class.run(code: "print('hi')", language: 'python', timeout_s: 2)
    expect(status.success?).to be true
    expect(out).to eq("hi\n")
    expect(err).to eq('')
  end

  it 'restituisce errore se il Pod non appare' do
    # kubectl apply
    expect(Open3).to receive(:capture3)
      .with('kubectl', 'apply', '-f', '-', '-n', 'default', anything)
      .and_return(["job.batch/ok created\n", '', instance_double(Process::Status, success?: true)])

    # get pod name polling: sempre vuoto
    allow(Open3).to receive(:capture3)
      .with('kubectl', 'get', 'pods', '-n', 'default', '-l', kind_of(String), '-o', 'jsonpath={.items[0].metadata.name}')
      .and_return(['', '', instance_double(Process::Status, success?: true)])

    # cleanup
    expect(Open3).to receive(:capture3)
      .with('kubectl', 'delete', 'job', kind_of(String), '-n', 'default', '--ignore-not-found=true')
      .and_return(['', '', instance_double(Process::Status, success?: true)])

    out, err, status = described_class.run(code: "puts 'x'", language: 'ruby', timeout_s: 1)
    expect(status.success?).to be false
    expect(out).to eq('')
    expect(err).to match(/Pod for job .* not found/)
  end
end


