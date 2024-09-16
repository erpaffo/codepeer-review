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
      if allowed_command?(data['input'])
        ShellProcessManager.send_input(@project, data['input'])
        Rails.logger.info "Received input for Project ID: #{@project.id}: #{data['input']}"
      else
        transmit({ error: "Command not allowed." })
        Rails.logger.warn "Attempted to execute disallowed command for Project ID: #{@project.id}: #{data['input']}"
      end
    else
      Rails.logger.warn "No project found for ShellChannel input."
    end
  end

  private

  def allowed_command?(input)
    allowed_commands = %w[
      gcc g++ python3 python java javac node bash ls pwd echo rustc
      make mvn yarn pip bundler mkdir touch rm rmdir cat cp mv cd
    ]

    # Verifica se il comando è un eseguibile locale (inizia con ./) o è nella lista dei comandi consentiti
    first_word = input.strip.split.first
    allowed_commands.include?(first_word) || input.strip.start_with?('./')
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
