class ShellProcessManager
  def self.initialize_shell(project, project_files_path)
    container_name = "project_executor_#{project.id}"
    env_vars = "PROJECT_ID=#{project.id} PROJECT_FILES_PATH=#{project_files_path}"

    # Verifica se il container esiste già
    return if container_running?(container_name)

    # Avvia il container Docker con i file del progetto
    command = "#{env_vars} docker-compose -f docker-images/docker-compose.yml run -d --rm --name #{container_name} project_executor"
    Rails.logger.info("Starting Docker container: #{command}")
    system(command)

    unless container_running?(container_name)
      Rails.logger.error("Failed to start Docker container for project #{project.id}")
    end
  end


  def self.send_input(project, input)
    container_name = "project_executor_#{project.id}"
    if container_running?(container_name)
      command = "docker exec #{container_name} bash -c '#{input}'"
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
    else
      Rails.logger.error("Docker container for project #{project.id} is not running.")
      ShellChannel.broadcast_to(project, { output: "Docker container for project #{project.id} is not running." })
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
