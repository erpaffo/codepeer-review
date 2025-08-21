# frozen_string_literal: true

require 'open3'

module Kube
  class Metrics
    def self.pod_metrics(project)
      return { available: false, reason: 'k8s_disabled' } unless Rails.configuration.x.k8s.enabled

      pod = ShellManager.find_pod_name(project)
      return { available: false, reason: 'no_pod' } if pod.to_s.empty?

      ns = Rails.configuration.x.k8s.namespace

      cpu_m = nil
      mem_bytes = nil
      out, _err, st = Open3.capture3('kubectl', 'top', 'pod', pod, '-n', ns, '--no-headers')
      if st.success? && !out.strip.empty?
        # Format: "pod-name  23m  110Mi"
        parts = out.split
        cpu_m = parse_millicores(parts[1]) rescue nil
        mem_bytes = parse_bytes(parts[2]) rescue nil
      end

      gpu = gpu_metrics(pod, ns)

      { available: true, cpu_millicores: cpu_m, memory_bytes: mem_bytes, gpu: gpu }
    rescue => e
      { available: false, reason: e.message }
    end

    def self.parse_millicores(value)
      # e.g., "23m" or "0" or "1"
      return value.to_i if value.end_with?('m')
      (value.to_f * 1000).to_i
    end

    def self.parse_bytes(value)
      # e.g., "110Mi", "1Gi"
      if value.end_with?('Ki')
        (value.to_i * 1024)
      elsif value.end_with?('Mi')
        (value.to_i * 1024 * 1024)
      elsif value.end_with?('Gi')
        (value.to_i * 1024 * 1024 * 1024)
      else
        value.to_i
      end
    end

    def self.gpu_metrics(pod, namespace)
      # Tries to query NVIDIA GPU metrics if available inside the pod
      cmd = ['kubectl', 'exec', pod, '-n', namespace, '--', 'nvidia-smi', '--query-gpu=utilization.gpu,memory.used', '--format=csv,noheader,nounits']
      out, _err, st = Open3.capture3(*cmd)
      return { available: false } unless st.success?
      # Output like: "12, 345"
      util, mem = out.split(',').map { |s| s.to_s.strip }
      { available: true, utilization_percent: util.to_i, memory_megabytes: mem.to_i }
    rescue
      { available: false }
    end
  end
end


