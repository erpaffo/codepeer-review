require 'open3'
require 'yaml'
namespace :images do
  LANGS = %w[python c cpp java javascript ruby rust ubuntu].freeze

  desc 'Build all runner images. Usage: rake images:build[registry,tag]'
  task :build, [:registry, :tag] do |_t, args|
    registry = (args[:registry] || ENV['REGISTRY'] || '').to_s.sub(%r{/$}, '')
    tag = args[:tag] || ENV['TAG'] || 'latest'

    LANGS.each do |lang|
      if lang == 'ubuntu'
        dockerfile = File.join('docker-images', 'Dockerfile')
        build_context = 'docker-images'
      else
        build_context = File.join('docker-images', lang)
        dockerfile = File.join(build_context, 'Dockerfile')
      end
      next unless File.exist?(dockerfile)

      image = [registry, "code-executor/#{lang}:#{tag}"].reject(&:empty?).join('/')
      puts "Building #{image} from #{dockerfile}"
      system("docker build -t #{image} -f #{dockerfile} #{build_context}") || abort("Failed to build #{image}")
    end
  end

  desc 'Push all runner images. Usage: rake images:push[registry,tag]'
  task :push, [:registry, :tag] do |_t, args|
    registry = (args[:registry] || ENV['REGISTRY'] || '').to_s.sub(%r{/$}, '')
    tag = args[:tag] || ENV['TAG'] || 'latest'

    LANGS.each do |lang|
      image = [registry, "code-executor/#{lang}:#{tag}"].reject(&:empty?).join('/')
      puts "Pushing #{image}"
      system("docker push #{image}") || abort("Failed to push #{image}")
    end
  end

  desc 'Pre-pull runner images locally (Docker host). Usage: rake images:prepull_local[registry,tag]'
  task :prepull_local, [:registry, :tag] do |_t, args|
    registry = (args[:registry] || ENV['REGISTRY'] || '').to_s.sub(%r{/$}, '')
    tag = args[:tag] || ENV['TAG'] || 'latest'

    LANGS.each do |lang|
      image = [registry, "code-executor/#{lang}:#{tag}"].reject(&:empty?).join('/')
      puts "Pulling #{image}"
      system("docker pull #{image}") || abort("Failed to pull #{image}")
    end
  end

  desc 'Pre-pull runner images on all K8s nodes via DaemonSet (requires kubectl). Usage: rake images:prepull_k8s[registry,tag,namespace]'
  task :prepull_k8s, [:registry, :tag, :namespace] do |_t, args|
    registry = (args[:registry] || ENV['REGISTRY'] || '').to_s.sub(%r{/$}, '')
    tag = args[:tag] || ENV['TAG'] || 'latest'
    ns = args[:namespace] || ENV['K8S_NAMESPACE'] || 'codepeer'

    init_containers = LANGS.map do |lang|
      image = [registry, "code-executor/#{lang}:#{tag}"].reject(&:empty?).join('/')
      {
        name: "pull-#{lang}",
        image: image,
        command: ['sh', '-c', 'echo "pulled"']
      }
    end

    ds = {
      apiVersion: 'apps/v1',
      kind: 'DaemonSet',
      metadata: { name: 'image-prepuller', namespace: ns, labels: { app: 'image-prepuller' } },
      spec: {
        selector: { matchLabels: { app: 'image-prepuller' } },
        template: {
          metadata: { labels: { app: 'image-prepuller' } },
          spec: {
            initContainers: init_containers,
            containers: [
              { name: 'pause', image: 'gcr.io/google-containers/pause:3.2', command: ['sh', '-c', 'sleep 3600'] }
            ]
          }
        }
      }
    }

    puts 'Applying DaemonSet to pre-pull images on all nodes'
    stdout, stderr, status = Open3.capture3('kubectl', 'apply', '-f', '-', stdin_data: ds.to_yaml)
    abort(stderr) unless status.success?
    puts stdout
  end
end


