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

        # Imposta directory corrente di sessione
        set_current_dir('/app')

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
      input = (data['input'] || '').to_s
      return if input.strip.empty?

      # Gestisci comandi speciali della shell
      if handle_special_commands(input)
        return
      end

      # Gestione 'cd' con persistenza directory
      if input.strip.start_with?('cd')
        handle_cd_command(input)
        return
      end

      if allowed_command?(input)
        ShellProcessManager.send_input(@project, input, current_dir: get_current_dir)
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
      transmit({ output: "History command - use Ctrl+R to search in history\r\n" })
      return true
    when 'docker-status'
      show_docker_status
      return true
    when /^create-file\s+(\S+)$/
      filename = $1
      create_empty_file(filename_in_pwd(filename))
      return true
    when /^edit-file\s+(\S+)\s+(.+)$/
      filename = $1
      content = $2
      edit_file_content(filename_in_pwd(filename), content)
      return true
    when /^append-file\s+(\S+)\s+(.+)$/
      filename = $1
      content = $2
      append_to_file(filename_in_pwd(filename), content)
      return true
    when /^alias\s+(\w+)=(.+)$/
      alias_name = $1
      alias_value = $2.strip
      store_alias(alias_name, alias_value)
      transmit({ output: "Alias '#{alias_name}' created\r\n" })
      return true
    when /^unalias\s+(\w+)$/
      alias_name = $1
      remove_alias(alias_name)
      transmit({ output: "Alias '#{alias_name}' removed\r\n" })
      return true
    when 'alias'
      show_aliases
      return true
    when /^export\s+(\w+)=(.+)$/
      var_name = $1
      var_value = $2.strip
      store_environment_variable(var_name, var_value)
      transmit({ output: "Environment variable '#{var_name}' set\r\n" })
      return true
    when 'env'
      show_environment_variables
      return true
    when 'help'
      show_help
      return true
    when /^python-venv$/
      create_python_venv
      return true
    when /^pip-install\s+(.+)$/
      install_pip_packages($1)
      return true
    when /^pip-freeze$/
      freeze_pip_packages
      return true
    end
    false
  end

  def handle_cd_command(input)
    parts = input.strip.split(/\s+/, 2)
    target = parts.length > 1 ? parts.last.strip : ''

    new_dir = resolve_target_dir(target)

    # Verifica esistenza directory nel container
    container_name = "project_executor_#{@project.id}"
    check_cmd = "docker exec #{container_name} bash -lc 'test -d #{escape_single_quotes(new_dir)}'"
    if system(check_cmd)
      set_current_dir(new_dir)
      transmit({ output: "#{new_dir}\r\n" })
    else
      transmit({ output: "cd: no such file or directory: #{target}\r\n" })
    end
  end

  def resolve_target_dir(target)
    base = get_current_dir || '/app'
    candidate = if target.nil? || target.empty? || target == '~'
      '/app'
    elsif target == '-'
      base # per semplicità, niente directory precedente
    elsif target.start_with?('/')
      target
    else
      "#{base}/#{target}"
    end

    # Normalizza path e confinalo sotto /app
    normalized = candidate.split('/').reject { |p| p.nil? || p.empty? || p == '.' }.inject([]) do |stack, part|
      if part == '..'
        stack.pop
      else
        stack << part
      end
      stack
    end
    normalized_path = '/' + normalized.join('/')

    unless normalized_path.start_with?('/app')
      '/app'
    else
      normalized_path
    end
  end

  def filename_in_pwd(name)
    dir = get_current_dir || '/app'
    resolve_target_dir(File.join(dir, name))
  end

  def get_current_dir
    Rails.cache.read(current_dir_cache_key) || '/app'
  end

  def set_current_dir(path)
    Rails.cache.write(current_dir_cache_key, path, expires_in: 2.hours)
  end

  def current_dir_cache_key
    user_id = (respond_to?(:current_user) && current_user ? current_user.id : 'anon')
    "shell_current_dir_#{@project.id}_#{user_id}"
  end

  def escape_single_quotes(str)
    str.to_s.gsub("'", %q('"'"'))
  end

  def show_docker_status
    container_name = "project_executor_#{@project.id}"
    unless system("docker --version > /dev/null 2>&1")
      transmit({ output: "Docker is not installed or not available\r\n" })
      return
    end
    project_containers = `docker ps --filter "name=project_executor_#{@project.id}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"`.strip
    if project_containers.include?("NAMES")
      transmit({ output: "Project containers:\r\n#{project_containers}\r\n\r\n" })
    else
      transmit({ output: "No project containers found.\r\n\r\n" })
    end
    if ShellProcessManager.container_running?(container_name)
      transmit({ output: "✅ Container #{container_name} is running\r\n" })
    else
      transmit({ output: "❌ Container #{container_name} is not running\r\n" })
      stopped_containers = `docker ps -a --filter "name=#{container_name}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"`.strip
      if stopped_containers.include?(container_name)
        transmit({ output: "Stopped containers:\r\n#{stopped_containers}\r\n" })
      end
    end
  end

  def store_alias(name, value)
    Rails.cache.write("shell_alias_#{@project.id}_#{name}", value, expires_in: 1.hour)
  end

  def remove_alias(name)
    Rails.cache.delete("shell_alias_#{@project.id}_#{name}")
  end

  def get_alias(name)
    Rails.cache.read("shell_alias_#{@project.id}_#{name}")
  end

  def show_aliases
    aliases = []
    if Rails.cache.respond_to?(:redis)
      Rails.cache.redis.keys("shell_alias_#{@project.id}_*").each do |key|
        name = key.split('_').last
        value = Rails.cache.read(key)
        aliases << "#{name}='#{value}'"
      end
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
    if Rails.cache.respond_to?(:redis)
      Rails.cache.redis.keys("shell_env_#{@project.id}_*").each do |key|
        name = key.split('_').last
        value = Rails.cache.read(key)
        env_vars << "#{name}=#{value}"
      end
    end
    env_vars << "PWD=#{get_current_dir}"
    env_vars << "USER=root"
    env_vars << "HOME=/root"
    env_vars << "SHELL=/bin/bash"
    transmit({ output: env_vars.join("\r\n") + "\r\n" })
  end

  def create_empty_file(filename)
    container_name = "project_executor_#{@project.id}"
    command = "docker exec #{container_name} touch #{escape_single_quotes(filename)}"
    if system(command)
      transmit({ output: "✅ File '#{filename}' created successfully\r\n" })
    else
      transmit({ output: "❌ Error creating file '#{filename}'\r\n" })
    end
  end

  def edit_file_content(filename, content)
    container_name = "project_executor_#{@project.id}"
    escaped_content = content.gsub("'", "'\"'\"'")
    command = "docker exec #{container_name} bash -c 'cd #{escape_single_quotes(get_current_dir)} && echo \"#{escaped_content}\" > #{escape_single_quotes(filename)}'"
    if system(command)
      transmit({ output: "✅ File '#{filename}' updated successfully\r\n" })
    else
      transmit({ output: "❌ Error updating file '#{filename}'\r\n" })
    end
  end

  def append_to_file(filename, content)
    container_name = "project_executor_#{@project.id}"
    escaped_content = content.gsub("'", "'\"'\"'")
    command = "docker exec #{container_name} bash -c 'cd #{escape_single_quotes(get_current_dir)} && echo \"#{escaped_content}\" >> #{escape_single_quotes(filename)}'"
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
      - python3, python, node, npm, pip-install, pip-freeze, python-venv
      - git, gcc, g++, make, echo, export, source
      - alias, unalias, history, clear, env, help

      Notes:
      - cd persists in this session. PWD: #{get_current_dir}
      - python-venv creates /app/.venv and enables pip-install
    HELP
    transmit({ output: help_text })
  end

  def allowed_command?(input)
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
      systemctl service pip-install pip-freeze python-venv
    ]
    first_word = expanded_input.strip.split.first
    allowed_commands.include?(first_word) || expanded_input.strip.start_with?('./')
  end

  def expand_aliases(input)
    words = input.strip.split
    return input if words.empty?
    first_word = words.first
    alias_value = get_alias(first_word)
    if alias_value
      words[0] = alias_value
      return words.join(' ')
    end
    input
  end

  # Python helpers
  def create_python_venv
    container_name = "project_executor_#{@project.id}"
    cmd = "docker exec #{container_name} bash -lc 'cd #{escape_single_quotes(get_current_dir)} && if command -v python3 >/dev/null 2>&1; then python3 -m venv /app/.venv && . /app/.venv/bin/activate && pip install --upgrade pip; else echo \"python3 not found\"; fi'"
    stdout, stderr, status = Open3.capture3(cmd)
    out = stdout.empty? ? stderr : stdout
    transmit({ output: out })
  end

  def install_pip_packages(packages)
    container_name = "project_executor_#{@project.id}"
    pkgs = packages.to_s.gsub(/[^\w\-\._\s\=\<\>\,\[\]\:]/, '')
    cmd = "docker exec #{container_name} bash -lc 'if [ ! -d /app/.venv ]; then python3 -m venv /app/.venv; fi; . /app/.venv/bin/activate && pip install #{pkgs}'"
    stdout, stderr, status = Open3.capture3(cmd)
    out = stdout.empty? ? stderr : stdout
    transmit({ output: out })
  end

  def freeze_pip_packages
    container_name = "project_executor_#{@project.id}"
    cmd = "docker exec #{container_name} bash -lc 'if [ -d /app/.venv ]; then . /app/.venv/bin/activate && pip freeze; else echo \"No venv at /app/.venv\"; fi'"
    stdout, stderr, status = Open3.capture3(cmd)
    out = stdout.empty? ? stderr : stdout
    transmit({ output: out })
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

      File.open(local_file_path, 'wb') do |local_file|
        s3.get_object(bucket: ENV['AWS_BUCKET'], key: s3_file_path) do |chunk|
          local_file.write(chunk)
        end
      end
    end

    local_dir
  end
end
