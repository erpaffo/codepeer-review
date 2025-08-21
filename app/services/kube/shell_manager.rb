# frozen_string_literal: true

require 'open3'
require 'yaml'

module Kube
  class ShellManager
    def self.initialize_shell(project, _project_files_path)
      raise 'Kubernetes is not enabled' unless Rails.configuration.x.k8s.enabled

      ensure_deployment(project)
      wait_for_pod_ready(project, timeout_s: 30)
    end

    def self.send_input(project, input)
      raise 'Kubernetes is not enabled' unless Rails.configuration.x.k8s.enabled

      pod = find_pod_name(project)
      return broadcast(project, "Error: shell pod not ready\r\n") if pod.nil? || pod.empty?

      command = [
        'kubectl', 'exec', pod, '-n', namespace,
        '--', 'bash', '-lc', input.to_s
      ]
      stdout, stderr, status = Open3.capture3(*command)
      output = stdout.empty? ? stderr : stdout
      if status.success?
        broadcast(project, output)
      else
        broadcast(project, "Error executing command: #{stderr}")
      end
    end

    def self.terminate_shell(project)
      raise 'Kubernetes is not enabled' unless Rails.configuration.x.k8s.enabled

      name = deployment_name(project)
      Open3.capture3('kubectl', 'delete', 'deployment', name, '-n', namespace, '--ignore-not-found=true')
    end

    def self.container_running?(project)
      pod = find_pod_name(project)
      !pod.to_s.empty?
    end

    # Internals
    def self.ensure_deployment(project)
      name = deployment_name(project)
      ns = namespace
      exists = system("kubectl get deploy #{name} -n #{ns} > /dev/null 2>&1")
      return if exists

      manifest = deployment_manifest(project)
      stdout, stderr, status = Open3.capture3('kubectl', 'apply', '-f', '-', '-n', ns, stdin_data: manifest.to_yaml)
      unless status.success?
        broadcast(project, "Error creating shell: #{stderr}\r\n")
      end
    end

    def self.deployment_manifest(project)
      name = deployment_name(project)
      img = Rails.configuration.x.k8s.shell_image
      {
        apiVersion: 'apps/v1',
        kind: 'Deployment',
        metadata: { name: name, namespace: namespace, labels: { app: 'project-shell', projectId: project.id.to_s } },
        spec: {
          replicas: 1,
          selector: { matchLabels: { app: 'project-shell', projectId: project.id.to_s } },
          template: {
            metadata: { labels: { app: 'project-shell', projectId: project.id.to_s } },
            spec: {
              restartPolicy: 'Always',
              imagePullSecrets: (Rails.configuration.x.k8s.image_pull_secret.present? ? [{ name: Rails.configuration.x.k8s.image_pull_secret }] : nil),
              containers: [
                {
                  name: 'shell',
                  image: img,
                  imagePullPolicy: Rails.configuration.x.k8s.image_pull_policy,
                  tty: true,
                  stdin: true,
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
                  command: ['bash', '-lc', 'while true; do sleep 3600; done']
                }
              ]
            }
          }
        }
      }
    end

    def self.wait_for_pod_ready(project, timeout_s: 30)
      end_time = Time.now + timeout_s
      loop do
        return false if Time.now > end_time
        pod = find_pod_name(project)
        return true unless pod.to_s.empty?
        sleep(0.5)
      end
    end

    def self.find_pod_name(project)
      label = "app=project-shell,projectId=#{project.id}"
      out, _err, _st = Open3.capture3('kubectl', 'get', 'pods', '-n', namespace, '-l', label, '-o', 'jsonpath={.items[0].metadata.name}')
      out.to_s.strip
    end

    def self.deployment_name(project)
      "project-shell-#{project.id}"
    end

    def self.namespace
      Rails.configuration.x.k8s.namespace
    end

    def self.broadcast(project, output)
      ShellChannel.broadcast_to(project, { output: output })
    end
  end
end


