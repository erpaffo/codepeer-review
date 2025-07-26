class ShellProcessManager
  def self.initialize_shell(project, project_files_path)
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
    # Usa 'up' invece di 'run' per mantenere il container in esecuzione
    command = "#{env_vars} docker-compose -f docker-images/docker-compose.yml up -d --no-deps project_executor"
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

    # Esegui il comando nel container
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

  def self.terminate_shell(project)
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
    `docker ps --filter "name=#{container_name}" --format "{{.Names}}"`.strip == container_name
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
