class ShellProcessManager
  def self.initialize_shell(project, project_files_path)
    if Rails.configuration.x.k8s.enabled
      return Kube::ShellManager.initialize_shell(project, project_files_path)
    end
    container_name = "project_executor_#{project.id}"
    env_vars = "PROJECT_ID=#{project.id} PROJECT_FILES_PATH=#{project_files_path}"

    # Verifica se Docker è installato e in esecuzione
    unless docker_available?
      Rails.logger.error("Docker is not available or not running")
      ShellChannel.broadcast_to(project, { output: "Error: Docker is not available or not running.\r\n" })
      return
    end

    # Verifica se il container esiste già e è in esecuzione
    if container_running?(container_name)
      Rails.logger.info("Container #{container_name} is already running")
      return
    end

    # Ferma e rimuovi container esistenti con lo stesso nome
    cleanup_existing_container(container_name)

    # Avvia il container Docker con i file del progetto
    # Usa docker run diretto invece di docker-compose per evitare problemi di network
    command = "docker run -d --name #{container_name} -v #{project_files_path}:/app -w /app code-executor/ubuntu:latest bash -c 'while true; do sleep 3600; done'"
    Rails.logger.info("Starting Docker container: #{command}")
    
    # Esegui il comando e cattura l'output
    stdout, stderr, status = Open3.capture3(command)
    
    if status.success?
      Rails.logger.info("Docker container started successfully")
      # Aspetta un momento per assicurarsi che il container sia completamente avviato
      sleep(2)
      
      unless container_running?(container_name)
        Rails.logger.error("Container started but not running. stdout: #{stdout}, stderr: #{stderr}")
        ShellChannel.broadcast_to(project, { output: "Error: Container started but not running.\r\n" })
      end
    else
      Rails.logger.error("Failed to start Docker container. stdout: #{stdout}, stderr: #{stderr}")
      ShellChannel.broadcast_to(project, { output: "Error: Failed to start Docker container: #{stderr}\r\n" })
    end
  end

    def self.send_input(project, input)
    if Rails.configuration.x.k8s.enabled
      return Kube::ShellManager.send_input(project, input)
    end
    container_name = "project_executor_#{project.id}"

    # Se il container non è in esecuzione, prova a riavviarlo
    unless container_running?(container_name)
      Rails.logger.warn("Container #{container_name} not running, attempting to restart...")
      project_files_path = download_project_files_from_s3(project)
      initialize_shell(project, project_files_path)
      
      # Aspetta un momento per l'avvio
      sleep(1)
      
      unless container_running?(container_name)
        Rails.logger.error("Failed to restart Docker container for project #{project.id}")
        ShellChannel.broadcast_to(project, { output: "Error: Docker container for project #{project.id} is not running and could not be restarted.\r\n" })
        return
      end
    end

    # Controlla se il comando è un editor interattivo
    interactive_commands = ['nano', 'vim', 'vi', 'emacs', 'pico']
    is_interactive = interactive_commands.any? { |cmd| input.strip.start_with?(cmd) }

    if is_interactive
      # Per comandi interattivi, usa docker exec con -it per TTY
      command = "docker exec -it #{container_name} bash -c '#{input.gsub("'", "'\"'\"'")}'"
      Rails.logger.info("Executing interactive command in Docker container: #{command}")
      
      # Per comandi interattivi, invia un messaggio informativo
      ShellChannel.broadcast_to(project, { output: "⚠️  Editor interattivo rilevato: #{input.split.first}\r\n" })
      ShellChannel.broadcast_to(project, { output: "💡 Suggerimento: Usa l'editor Monaco integrato per modificare i file\r\n" })
      ShellChannel.broadcast_to(project, { output: "   Oppure usa comandi non interattivi come: cat, head, tail, grep\r\n" })
      ShellChannel.broadcast_to(project, { output: "   Per creare file: echo 'contenuto' > filename.txt\r\n" })
      ShellChannel.broadcast_to(project, { output: "   Per modificare file: sed -i 's/old/new/g' filename.txt\r\n" })
    else
      # Per comandi non interattivi, usa il metodo normale
      command = "docker exec #{container_name} bash -c '#{input.gsub("'", "'\"'\"'")}'"
      Rails.logger.info("Executing command in Docker container: #{command}")

      # Cattura l'output del comando
      stdout, stderr, status = Open3.capture3(command)

      output = stdout.empty? ? stderr : stdout
      Rails.logger.info("Command output: #{output}")

      if status.success?
        ShellChannel.broadcast_to(project, { output: output })
      else
        ShellChannel.broadcast_to(project, { output: "Error executing command: #{stderr}" })
      end
    end
  end

  def self.terminate_shell(project)
    if Rails.configuration.x.k8s.enabled
      return Kube::ShellManager.terminate_shell(project)
    end
    container_name = "project_executor_#{project.id}"
    if container_running?(container_name)
      command = "docker stop #{container_name}"
      Rails.logger.info("Stopping Docker container: #{command}")
      system(command)
    else
      Rails.logger.warn("Docker container for project #{project.id} is not running, cannot terminate.")
    end
  end

  def self.container_running?(container_name)
    if Rails.configuration.x.k8s.enabled
      project_id = container_name.to_s.sub('project_executor_', '')
      project = Project.find_by(id: project_id)
      return false unless project
      return Kube::ShellManager.container_running?(project)
    else
      `docker ps --filter "name=#{container_name}" --format "{{.Names}}"`.strip == container_name
    end
  end

  private

  def self.docker_available?
    system("docker --version > /dev/null 2>&1") && system("docker ps > /dev/null 2>&1")
  end

  def self.cleanup_existing_container(container_name)
    # Ferma il container se è in esecuzione
    system("docker stop #{container_name} > /dev/null 2>&1")
    # Rimuovi il container se esiste
    system("docker rm #{container_name} > /dev/null 2>&1")
  end

  def self.download_project_files_from_s3(project)
    user_folder_name = project.user.email.split('@').first
    project_folder_name = project.title.parameterize
    local_dir = Rails.root.join('tmp', 'projects', "#{project.id}_files")

    FileUtils.mkdir_p(local_dir)

    s3 = Aws::S3::Client.new(region: ENV['AWS_REGION'])

    project.project_files.each do |file|
      s3_file_path = "uploads/#{user_folder_name}/#{project_folder_name}/#{file.file_identifier}"
      local_file_path = File.join(local_dir, file.file_identifier)

      # Scarica il file da S3 e salva nel percorso locale
      File.open(local_file_path, 'wb') do |local_file|
        s3.get_object(bucket: ENV['AWS_BUCKET'], key: s3_file_path) do |chunk|
          local_file.write(chunk)
        end
      end
    end

    local_dir
  end

  def self.map_language_to_service(language)
    case language
    when 'Python' then 'python'
    when 'C' then 'c'
    when 'C++' then 'cpp'
    when 'JavaScript' then 'javascript'
    when 'Ruby' then 'ruby'
    when 'Java' then 'java'
    when 'Rust' then 'rust'
    else
      raise "Unsupported language: #{language}"
    end
  end
end
