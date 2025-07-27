class ShellChannel < ApplicationCable::Channel
  def subscribed
    if params[:project_id].present?
      @project = Project.find_by(id: params[:project_id])
      if @project
        stream_for @project

        # Scarica i file del progetto da S3 e ottieni il percorso locale
        project_files_path = download_project_files_from_s3(@project)

        # Inizializza la shell nel container Docker con i file del progetto
        ShellProcessManager.initialize_shell(@project, project_files_path)

        Rails.logger.info "Subscribed to ShellChannel for Project ID: #{@project.id}"
      else
        reject
        Rails.logger.warn "ShellChannel subscription rejected: Project ID #{params[:project_id]} not found."
      end
    else
      reject
      Rails.logger.warn "ShellChannel subscription rejected: project_id parameter missing."
    end
  end

  def unsubscribed
    if @project
      ShellProcessManager.terminate_shell(@project)
      Rails.logger.info "Unsubscribed from ShellChannel for Project ID: #{@project.id}"
    end
  end

  def send_input(data)
    if @project
      input = data['input']
      
      # Gestisci comandi speciali della shell
      if handle_special_commands(input)
        return
      end
      
      if allowed_command?(input)
        ShellProcessManager.send_input(@project, input)
        Rails.logger.info "Received input for Project ID: #{@project.id}: #{input}"
      else
        transmit({ error: "Command not allowed." })
        Rails.logger.warn "Attempted to execute disallowed command for Project ID: #{@project.id}: #{input}"
      end
    else
      Rails.logger.warn "No project found for ShellChannel input."
    end
  end

  private

  def handle_special_commands(input)
    case input.strip
    when 'history'
      # Mostra la cronologia dei comandi (gestita lato client)
      transmit({ output: "History command - use Ctrl+R to search in history\r\n" })
      return true
    when 'docker-status'
      # Mostra lo stato dei container Docker
      show_docker_status
      return true
    when /^create-file\s+(\S+)$/
      # Crea un nuovo file vuoto
      filename = $1
      create_empty_file(filename)
      return true
    when /^edit-file\s+(\S+)\s+(.+)$/
      # Modifica un file con contenuto specifico
      filename = $1
      content = $2
      edit_file_content(filename, content)
      return true
    when /^append-file\s+(\S+)\s+(.+)$/
      # Aggiunge contenuto a un file
      filename = $1
      content = $2
      append_to_file(filename, content)
      return true
    when /^alias\s+(\w+)=(.+)$/
      # Gestisci alias
      alias_name = $1
      alias_value = $2.strip
      store_alias(alias_name, alias_value)
      transmit({ output: "Alias '#{alias_name}' created\r\n" })
      return true
    when /^unalias\s+(\w+)$/
      # Rimuovi alias
      alias_name = $1
      remove_alias(alias_name)
      transmit({ output: "Alias '#{alias_name}' removed\r\n" })
      return true
    when 'alias'
      # Mostra tutti gli alias
      show_aliases
      return true
    when /^export\s+(\w+)=(.+)$/
      # Gestisci variabili d'ambiente
      var_name = $1
      var_value = $2.strip
      store_environment_variable(var_name, var_value)
      transmit({ output: "Environment variable '#{var_name}' set\r\n" })
      return true
    when 'env'
      # Mostra variabili d'ambiente
      show_environment_variables
      return true
    when 'help'
      # Mostra aiuto
      show_help
      return true
    end
    false
  end

  def show_docker_status
    container_name = "project_executor_#{@project.id}"
    
    # Verifica se Docker è disponibile
    unless system("docker --version > /dev/null 2>&1")
      transmit({ output: "Docker is not installed or not available\r\n" })
      return
    end
    
    # Mostra solo i container rilevanti per questo progetto
    project_containers = `docker ps --filter "name=project_executor_#{@project.id}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"`.strip
    
    if project_containers.include?("NAMES")
      transmit({ output: "Project containers:\r\n#{project_containers}\r\n\r\n" })
    else
      transmit({ output: "No project containers found.\r\n\r\n" })
    end
    
    # Verifica se il container specifico è in esecuzione
    if ShellProcessManager.container_running?(container_name)
      transmit({ output: "✅ Container #{container_name} is running\r\n" })
    else
      transmit({ output: "❌ Container #{container_name} is not running\r\n" })
      
      # Mostra container fermati
      stopped_containers = `docker ps -a --filter "name=#{container_name}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"`.strip
      if stopped_containers.include?(container_name)
        transmit({ output: "Stopped containers:\r\n#{stopped_containers}\r\n" })
      end
    end
  end

  def store_alias(name, value)
    # Salva l'alias nel database o in memoria
    Rails.cache.write("shell_alias_#{@project.id}_#{name}", value, expires_in: 1.hour)
  end

  def remove_alias(name)
    Rails.cache.delete("shell_alias_#{@project.id}_#{name}")
  end

  def get_alias(name)
    Rails.cache.read("shell_alias_#{@project.id}_#{name}")
  end

  def show_aliases
    # Recupera tutti gli alias per questo progetto
    aliases = []
    Rails.cache.redis.keys("shell_alias_#{@project.id}_*").each do |key|
      name = key.split('_').last
      value = Rails.cache.read(key)
      aliases << "#{name}='#{value}'"
    end
    
    if aliases.empty?
      transmit({ output: "No aliases defined\r\n" })
    else
      transmit({ output: aliases.join("\r\n") + "\r\n" })
    end
  end

  def store_environment_variable(name, value)
    Rails.cache.write("shell_env_#{@project.id}_#{name}", value, expires_in: 1.hour)
  end

  def get_environment_variable(name)
    Rails.cache.read("shell_env_#{@project.id}_#{name}")
  end

  def show_environment_variables
    env_vars = []
    Rails.cache.redis.keys("shell_env_#{@project.id}_*").each do |key|
      name = key.split('_').last
      value = Rails.cache.read(key)
      env_vars << "#{name}=#{value}"
    end
    
    # Aggiungi variabili di sistema
    env_vars << "PWD=/app"
    env_vars << "USER=root"
    env_vars << "HOME=/root"
    env_vars << "SHELL=/bin/bash"
    
    transmit({ output: env_vars.join("\r\n") + "\r\n" })
  end

  def create_empty_file(filename)
    container_name = "project_executor_#{@project.id}"
    command = "docker exec #{container_name} touch #{filename}"
    
    if system(command)
      transmit({ output: "✅ File '#{filename}' created successfully\r\n" })
    else
      transmit({ output: "❌ Error creating file '#{filename}'\r\n" })
    end
  end

  def edit_file_content(filename, content)
    container_name = "project_executor_#{@project.id}"
    # Escapa il contenuto per evitare problemi con caratteri speciali
    escaped_content = content.gsub("'", "'\"'\"'")
    command = "docker exec #{container_name} bash -c 'echo \"#{escaped_content}\" > #{filename}'"
    
    if system(command)
      transmit({ output: "✅ File '#{filename}' updated successfully\r\n" })
    else
      transmit({ output: "❌ Error updating file '#{filename}'\r\n" })
    end
  end

  def append_to_file(filename, content)
    container_name = "project_executor_#{@project.id}"
    # Escapa il contenuto per evitare problemi con caratteri speciali
    escaped_content = content.gsub("'", "'\"'\"'")
    command = "docker exec #{container_name} bash -c 'echo \"#{escaped_content}\" >> #{filename}'"
    
    if system(command)
      transmit({ output: "✅ Content appended to '#{filename}' successfully\r\n" })
    else
      transmit({ output: "❌ Error appending to file '#{filename}'\r\n" })
    end
  end

  def show_help
    help_text = <<~HELP
      Available commands:
      - ls, cd, pwd, cat, cp, mv, rm, mkdir, rmdir, touch
      - grep, find, chmod, chown, ps, top, kill
      - python3, python, node, npm
      - git, gcc, g++, make, echo, export, source
      - alias, unalias, history, clear, env, help
      
      File management commands:
      - create-file filename: Create empty file
      - edit-file filename content: Create/overwrite file with content
      - append-file filename content: Append content to file
      - echo "content" > filename: Create file with content
      - echo "content" >> filename: Append to file
      - cat filename: View file content
      
      Note: Interactive editors (nano, vim) are not supported in this terminal.
      Use the Monaco Editor in the left panel for interactive file editing.
      
      Keyboard shortcuts:
      - Tab: Auto-completion
      - Ctrl+R: Search in history
      - Ctrl+C: Interrupt command
      - Ctrl+L: Clear screen
      - Ctrl+W: Delete word
      - Ctrl+U: Delete line before cursor
      - Ctrl+A: Go to beginning of line
      - Ctrl+E: Go to end of line
      - Arrow keys: Navigate command history and cursor
      
      Special commands:
      - alias name='command': Create alias
      - unalias name: Remove alias
      - export VAR=value: Set environment variable
      - env: Show environment variables
      - help: Show this help
    HELP
    transmit({ output: help_text })
  end

  def allowed_command?(input)
    # Espandi alias prima di controllare
    expanded_input = expand_aliases(input)
    
    allowed_commands = %w[
      gcc g++ python3 python java javac node bash ls pwd echo rustc
      make mvn yarn pip bundler mkdir touch rm rmdir cat cp mv cd
      grep find chmod chown clear ps top kill nano vim git
      head tail less more wc sort uniq cut sed awk
      curl wget tar gzip gunzip zip unzip
      whoami id groups sudo su
      date cal uptime free df du
      ping traceroute netstat ss
      systemctl service 
    ]

    # Verifica se il comando è un eseguibile locale (inizia con ./) o è nella lista dei comandi consentiti
    first_word = expanded_input.strip.split.first
    allowed_commands.include?(first_word) || expanded_input.strip.start_with?('./')
  end

  def expand_aliases(input)
    words = input.strip.split
    return input if words.empty?
    
    first_word = words.first
    alias_value = get_alias(first_word)
    
    if alias_value
      # Sostituisci il primo comando con l'alias
      words[0] = alias_value
      return words.join(' ')
    end
    
    input
  end

  # Funzione per scaricare i file da S3
  def download_project_files_from_s3(project)
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

    local_dir # Restituisce il percorso locale dove i file sono stati scaricati
  end
end
