# frozen_string_literal: true

require 'open3'
require 'securerandom'
require 'yaml'
require 'json'

module Kube
  class RawJobRunner
    def self.run(image:, command:, timeout_s: 300, env: {}, cpu_limit: nil, memory_limit: nil, name_prefix: 'stress')
      raise ArgumentError, 'image must be present' if image.nil? || image.empty?
      raise ArgumentError, 'command must be present' if command.nil? || command.empty?
      unless Rails.configuration.x.k8s.enabled
        raise 'Kubernetes is not enabled'
      end

      job_name = "#{name_prefix}-#{SecureRandom.hex(6)}"
      namespace = Rails.configuration.x.k8s.namespace
      deadline = timeout_s

      limits_cpu = cpu_limit || Rails.configuration.x.k8s.job_cpu_limit
      limits_mem = memory_limit || Rails.configuration.x.k8s.job_memory_limit

      env_arr = env.map { |k, v| { name: k.to_s, value: v.to_s } }

      manifest = {
        apiVersion: 'batch/v1',
        kind: 'Job',
        metadata: { name: job_name, namespace: namespace, labels: { purpose: 'stress' } },
        spec: {
          backoffLimit: 0,
          activeDeadlineSeconds: deadline,
          template: {
            metadata: { labels: { job: job_name, purpose: 'stress' } },
            spec: {
              restartPolicy: 'Never',
              containers: [
                {
                  name: 'runner',
                  image: image,
                  imagePullPolicy: Rails.configuration.x.k8s.image_pull_policy,
                  securityContext: {
                    runAsNonRoot: true,
                    allowPrivilegeEscalation: false,
                    seccompProfile: { type: 'RuntimeDefault' },
                    capabilities: { drop: ['ALL'] }
                  },
                  resources: {
                    limits: { cpu: limits_cpu, memory: limits_mem },
                    requests: { cpu: '200m', memory: '256Mi' }
                  },
                  env: env_arr,
                  command: Array(command)
                }
              ]
            }
          }
        }
      }

      stdout_apply, stderr_apply, status_apply = Open3.capture3('kubectl', 'apply', '-f', '-', '-n', namespace, stdin_data: manifest.to_json)
      return ['', "Failed to create job: #{stderr_apply}", status_apply] unless status_apply.success?

      pod_name = wait_for_pod(name_label: job_name, namespace: namespace)
      if pod_name.nil?
        cleanup_job(job_name, namespace)
        return ['', "Pod for job #{job_name} not found", Struct.new(:success?).new(false)]
      end

      completed = wait_for_pod_completion(pod_name, namespace, timeout_s)
      stdout_logs, stderr_logs, _st_logs = Open3.capture3('kubectl', 'logs', pod_name, '-n', namespace)
      exit_code = container_exit_code(pod_name, namespace)
      status_obj = Struct.new(:success?).new(exit_code == 0)

      cleanup_job(job_name, namespace)
      [stdout_logs, completed ? stderr_logs : (stderr_logs + "\nTimeout"), status_obj]
    rescue => e
      ["", e.message, Struct.new(:success?).new(false)]
    end

    def self.wait_for_pod(name_label:, namespace:)
      get_pod_cmd = ['kubectl', 'get', 'pods', '-n', namespace, '-l', "job-name=#{name_label}", '-o', 'jsonpath={.items[0].metadata.name}']
      100.times do
        stdout_pod, _stderr_pod, _status_pod = Open3.capture3(*get_pod_cmd)
        return stdout_pod.strip unless stdout_pod.to_s.strip.empty?
        sleep(0.2)
      end
      nil
    end

    def self.wait_for_pod_completion(pod_name, namespace, timeout_s)
      end_time = Time.now + timeout_s
      loop do
        return false if Time.now > end_time
        out, _err, _st = Open3.capture3('kubectl', 'get', 'pod', pod_name, '-n', namespace, '-o', 'jsonpath={.status.phase}')
        return true if %w[Succeeded Failed].include?(out.strip)
        sleep(0.5)
      end
    end

    def self.container_exit_code(pod_name, namespace)
      out, _err, _st = Open3.capture3('kubectl', 'get', 'pod', pod_name, '-n', namespace, '-o', 'jsonpath={.status.containerStatuses[0].state.terminated.exitCode}')
      Integer(out) rescue 1
    end

    def self.cleanup_job(job_name, namespace)
      Open3.capture3('kubectl', 'delete', 'job', job_name, '-n', namespace, '--ignore-not-found=true')
    end
  end
end


