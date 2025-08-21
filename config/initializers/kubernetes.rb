# frozen_string_literal: true

# Minimal Kubernetes configuration behind a feature flag.
# When K8S_ENABLED is not true, the app keeps using Docker execution.

Rails.application.configure do
  config.x.k8s = ActiveSupport::OrderedOptions.new
  config.x.k8s.enabled = ENV.fetch('K8S_ENABLED', 'false').to_s.downcase == 'true'
  config.x.k8s.namespace = ENV.fetch('K8S_NAMESPACE', 'codepeer')
  config.x.k8s.job_active_deadline_seconds = ENV.fetch('K8S_JOB_TIMEOUT_SECONDS', '10').to_i
  config.x.k8s.job_cpu_limit = ENV.fetch('K8S_JOB_CPU_LIMIT', '500m')
  config.x.k8s.job_memory_limit = ENV.fetch('K8S_JOB_MEMORY_LIMIT', '256Mi')
  config.x.k8s.image_pull_policy = ENV.fetch('K8S_IMAGE_PULL_POLICY', 'IfNotPresent')

  # Registry configuration
  config.x.k8s.image_registry = ENV['IMAGE_REGISTRY'].to_s # e.g. "ghcr.io/USER" or "USERNAME"
  config.x.k8s.image_tag = ENV.fetch('IMAGE_TAG', 'latest')
  config.x.k8s.image_pull_secret = ENV['K8S_IMAGE_PULL_SECRET'] # optional secret name for private registry
  # Shell image used by Kube::ShellManager
  default_shell_image = ['code-executor', 'ubuntu'].join('/') + ":#{config.x.k8s.image_tag}"
  config.x.k8s.shell_image = if config.x.k8s.image_registry.present?
                               [config.x.k8s.image_registry, 'code-executor/ubuntu'].join('/') + ":#{config.x.k8s.image_tag}"
                             else
                               default_shell_image
                             end
end


