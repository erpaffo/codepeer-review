# frozen_string_literal: true

require 'open3'
require 'securerandom'
require 'base64'
require 'yaml'
require 'json'

module Kube
  class JobRunner
    # Public API
    # run(code:, language:, timeout_s:) -> { stdout:, stderr:, status: #<Process::Status-like> }
    def self.run(code:, language:, timeout_s: 5)
      raise ArgumentError, 'code must be present' if code.nil? || code.empty?
      raise ArgumentError, 'language must be present' if language.nil? || language.empty?

      unless Rails.configuration.x.k8s.enabled
        raise 'Kubernetes is not enabled'
      end

      job_name = "code-run-#{language}-#{SecureRandom.hex(6)}"
      namespace = Rails.configuration.x.k8s.namespace
      deadline = [timeout_s, Rails.configuration.x.k8s.job_active_deadline_seconds].min

      # Build the job manifest on the fly to avoid extra templates and keep things atomic.
      # Strategy: pass code via env (base64), entrypoint writes it to main file and executes.
      image, file_name, exec_cmd = image_and_command_for(language)
      image = qualify_image(image)

      manifest = {
        apiVersion: 'batch/v1',
        kind: 'Job',
        metadata: { name: job_name, namespace: namespace, labels: { purpose: 'snippet', language: language } },
        spec: {
          backoffLimit: 0,
          activeDeadlineSeconds: deadline,
          template: {
            metadata: { labels: { job: job_name, purpose: 'snippet', language: language } },
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
                    limits: { cpu: Rails.configuration.x.k8s.job_cpu_limit, memory: Rails.configuration.x.k8s.job_memory_limit },
                    requests: { cpu: '100m', memory: '128Mi' }
                  },
                  env: [
                    { name: 'CODE_B64', value: Base64.strict_encode64(code) },
                    { name: 'FILENAME', value: file_name }
                  ],
                  command: ['sh', '-lc', "echo \"$CODE_B64\" | base64 -d > \"$FILENAME\" && #{exec_cmd}"]
                }
              ]
            }.tap do |spec|
              pull_secret = Rails.configuration.x.k8s.image_pull_secret
              if pull_secret.present?
                spec[:imagePullSecrets] = [{ name: pull_secret }]
              end
            end
          }
        }
      }

      # Apply the job
      apply_cmd = [
        'kubectl', 'apply', '-f', '-',
        '-n', namespace
      ]

      stdout_apply, stderr_apply, status_apply = Open3.capture3(*apply_cmd, stdin_data: manifest.to_json)
      unless status_apply.success?
        return ['','Failed to create job: ' + stderr_apply, status_apply]
      end

      # Wait for pod to start and finish, then fetch logs
      get_pod_cmd = [
        'kubectl', 'get', 'pods', '-n', namespace, '-l', "job-name=#{job_name}", '-o', 'jsonpath={.items[0].metadata.name}'
      ]

      pod_name = nil
      50.times do
        stdout_pod, _stderr_pod, _status_pod = Open3.capture3(*get_pod_cmd)
        unless stdout_pod.to_s.strip.empty?
          pod_name = stdout_pod.strip
          break
        end
        sleep(0.1)
      end

      if pod_name.nil?
        cleanup_job(job_name, namespace)
        return ['', "Pod for job #{job_name} not found", double_status(false)]
      end

      # Wait for completion up to timeout
      completed = wait_for_pod_completion(pod_name, namespace, timeout_s)

      logs_cmd = ['kubectl', 'logs', pod_name, '-n', namespace]
      stdout_logs, stderr_logs, _status_logs = Open3.capture3(*logs_cmd)

      # Describe container exit code
      exit_code = container_exit_code(pod_name, namespace)
      status_obj = double_status(exit_code == 0)

      cleanup_job(job_name, namespace)

      if completed
        [stdout_logs, stderr_logs, status_obj]
      else
        [stdout_logs, "Timeout after #{timeout_s}s", status_obj]
      end
    rescue => e
      ["", e.message, double_status(false)]
    end

    def self.image_and_command_for(language)
      case language
      when 'python'
        ['code-executor/python:latest', 'main.py', 'python3 main.py']
      when 'c'
        ['code-executor/c:latest', 'main.c', 'sh -lc "gcc -o main main.c && ./main"']
      when 'cpp'
        ['code-executor/cpp:latest', 'main.cpp', 'sh -lc "g++ -o main main.cpp && ./main"']
      when 'java'
        ['code-executor/java:latest', 'Main.java', 'sh -lc "javac Main.java && java Main"']
      when 'javascript'
        ['code-executor/javascript:latest', 'main.js', 'node main.js']
      when 'ruby'
        ['code-executor/ruby:latest', 'main.rb', 'ruby main.rb']
      when 'rust'
        ['code-executor/rust:latest', 'main.rs', 'sh -lc "rustc main.rs && ./main"']
      else
        ['code-executor/python:latest', 'main.py', 'python3 main.py']
      end
    end

    def self.qualify_image(image)
      registry = Rails.configuration.x.k8s.image_registry
      return image if registry.blank?
      # if image already qualified, return as is
      return image if image.include?('/') && image.split('/').first.include?('.')
      [registry, image].join('/')
    end

    def self.wait_for_pod_completion(pod_name, namespace, timeout_s)
      end_time = Time.now + timeout_s
      loop do
        return false if Time.now > end_time
        out, _err, _st = Open3.capture3('kubectl', 'get', 'pod', pod_name, '-n', namespace, '-o', 'jsonpath={.status.phase}')
        case out.strip
        when 'Succeeded', 'Failed'
          return true
        end
        sleep(0.2)
      end
    end

    def self.container_exit_code(pod_name, namespace)
      out, _err, _st = Open3.capture3('kubectl', 'get', 'pod', pod_name, '-n', namespace, '-o', 'jsonpath={.status.containerStatuses[0].state.terminated.exitCode}')
      Integer(out) rescue 1
    end

    def self.cleanup_job(job_name, namespace)
      Open3.capture3('kubectl', 'delete', 'job', job_name, '-n', namespace, '--ignore-not-found=true')
    end

    def self.double_status(success)
      # Minimal object duck-typing Process::Status.success?
      Struct.new(:success?).new(!!success)
    end
  end
end


