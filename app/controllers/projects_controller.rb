class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [:show, :edit, :update, :destroy, :show_file, :edit_file, :update_file, :new_file, :upload_files, :create_file, :commit_logs, :toggle_favorite, :stats, :update_permissions, :upload, :upload_to_google_drive, :upload_to_github, :upload_to_gitlab, :run_shell]

  SUPPORTED_LANGUAGES = %w[python c cpp javascript ruby java rust].freeze

  def index
    @projects = current_user.projects + current_user.collaborated_projects
  end

  def show
    if @project.visibility == 'private' && @project.user != current_user && !@project.collaborating_users.include?(current_user)
      redirect_to projects_path, alert: 'You are not authorized to view this project.'
    elsif @project.user == current_user || @project.collaborating_users.include?(current_user)
      render :show
    else
      render :public_view
    end

    record_view
  end

  def new
    @project = current_user.projects.build
    @project.project_files.build
  end

  def create
    @project = current_user.projects.build(project_params)

    if @project.save
      begin
        ActiveRecord::Base.transaction do
          send_collaborator_invitations if params[:collaborator_emails].present?
        end
        redirect_to upload_files_project_path(@project), notice: 'Project was successfully created. Now upload your files.'
      rescue => e
        Rails.logger.error "Failed to create project: #{e.message}"
        @project.destroy  # Elimina il progetto se c'è un errore
        @project.errors.add(:base, e.message)
        render :new
      end
    else
      render :new
    end
  end

  def upload_file
    @project = Project.find(params[:id])
    @file = @project.project_files.build(file: params[:file])

    if @file.save
      render json: { message: "File uploaded successfully" }, status: :created
    else
      render json: { errors: @file.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def upload_files
    # Logica per l'upload multiplo dei file
  end

  def edit
    unless authorized_to_edit?
      redirect_to projects_path, alert: 'You are not authorized to edit this project.'
    end
  end

  def update
    unless authorized_to_edit?
      redirect_to projects_path, alert: 'You are not authorized to update this project.'
    else
      if @project.update(project_params)
        redirect_to @project, notice: 'Project was successfully updated.'
      else
        render :edit
      end
    end
  end

  def destroy
    unless @project.user == current_user
      redirect_to projects_path, alert: 'You are not authorized to delete this project.'
    else
      @project.destroy
      redirect_to projects_url, notice: 'Project was successfully destroyed.'
    end
  end

  def show_file
    @file = @project.project_files.find(params[:file_id])
    local_path = download_file_from_s3(@file)

    @file_content = read_file_content(local_path)

    respond_to do |format|
      format.html
      format.json { render json: { file_content: @file_content } }
    end
  end

  def edit_file
    @file = @project.project_files.find(params[:file_id])
    local_path = download_file_from_s3(@file)

    @file_content = read_file_content(local_path)

    Rails.logger.debug "File content being passed to the view: #{@file_content.inspect}"

    respond_to do |format|
      format.html
      format.json { render json: { file_content: @file_content } }
    end
  end

  def update_file
    @file = @project.project_files.find(params[:file_id])
    new_file_content = params[:project_file][:file]

    begin
      # Decode JSON string if needed
      new_file_content.gsub!(/\\n/, "\n")
      new_file_content_utf8 = new_file_content.encode('UTF-8')

      # Download the original file content from S3
      local_path = download_file_from_s3(@file)
      original_file_content = read_file_content(local_path)

      # Calculate the diff between the original and new content
      diff = Diffy::Diff.new(original_file_content, new_file_content_utf8, context: 3).to_s(:html)

      # Create a commit log entry with the diff
      @project.commit_logs.create!(
        file: @file,
        user: current_user,
        message: "Updated #{@file.file_identifier}",
        diff: diff
      )

      # Update the file content in S3
      s3 = Aws::S3::Resource.new
      obj = s3.bucket(ENV['AWS_BUCKET']).object(@file.file.path)
      obj.put(body: new_file_content_utf8)

      redirect_to project_path(@project), notice: 'File was successfully updated.'
    rescue => e
      Rails.logger.error "Errore nell'elaborazione del file: #{e.message}"
      render json: { error: 'File processing error' }, status: :unprocessable_entity
    end
  end

  def run_code
    code = params[:code]
    language = params[:language]

    # Validazione dei parametri
    unless code.present? && supported_language?(language)
      render json: { error: 'Invalid code or language.' }, status: :unprocessable_entity and return
    end

    begin
      output, error, status = execute_code_in_docker(code, language)
      if status.success?
        render json: { output: output }, status: :ok
      else
        render json: { error: error }, status: :unprocessable_entity
      end
    rescue Timeout::Error
      render json: { error: 'Code execution timed out.' }, status: :unprocessable_entity
    rescue => e
      Rails.logger.error "Errore durante l'esecuzione del codice: #{e.message}"
      render json: { error: 'An unexpected error occurred.' }, status: :internal_server_error
    end
  end

  def new_file
    @project_file = @project.project_files.build
  end

  def create_file
    file_name = params[:file_name]
    extension = params[:extension]

    if file_name.blank? || extension.blank?
      flash[:alert] = "File name and extension can't be blank."
      render :new_file and return
    end

    full_file_name = "#{file_name}.#{extension}"
    file_path = "#{Rails.root}/tmp/#{full_file_name}"

    FileUtils.mkdir_p(File.dirname(file_path))
    File.open(file_path, "w") {}

    @project_file = @project.project_files.build(file: File.open(file_path))

    if @project_file.save
      redirect_to edit_file_project_path(@project, file_id: @project_file.id), notice: 'File was successfully created.'
    else
      render :new_file
    end
  end

  def public_view
    @project = Project.find(params[:id])
    @files = @project.project_files
    if @project.visibility != 'public'
      redirect_to root_path, alert: "This project is not public."
    end
  end

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


  def download_project
    project = Project.find(params[:id])
    user_folder_name = project.user.email.split('@').first
    project_folder_name = project.title.parameterize

    s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'])
    bucket = s3.bucket(ENV['AWS_BUCKET'])
    zipfile_name = "#{project_folder_name}.zip"

    Tempfile.open(zipfile_name) do |tempfile|
      Zip::OutputStream.open(tempfile.path) do |zos|
        project.project_files.each do |file|
          file_path = "uploads/#{user_folder_name}/#{project_folder_name}/#{file.file_identifier}"
          obj = bucket.object(file_path)
          zos.put_next_entry(file.file_identifier)
          zos.print obj.get.body.read
        end
      end

      send_file tempfile.path, type: 'application/zip', disposition: 'attachment', filename: zipfile_name
    end
  end

  def download_file
    file = ProjectFile.find(params[:id])
    user_folder_name = file.project.user.email.split('@').first
    project_folder_name = file.project.title.parameterize
    file_path = "uploads/#{user_folder_name}/#{project_folder_name}/#{file.file_identifier}"

    s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'])
    obj = s3.bucket(ENV['AWS_BUCKET']).object(file_path)

    send_data obj.get.body.read, filename: file.file_identifier, type: obj.content_type, disposition: 'attachment'
  end

  def invite_collaborator
    email = params[:email]
    collaborator_user = User.find_by(email: email)

    if collaborator_user
      @invitation = @project.collaborator_invitations.build(email: email, user: collaborator_user)

      if @invitation.save
        begin
          CollaboratorMailer.invite_email(@invitation).deliver_now
          redirect_to @project, notice: "Invitation sent to #{email}."
        rescue StandardError => e
          @project.errors.add(:base, "Failed to send the invitation. Error: #{e.message}")
          render :edit
        end
      else
        render :edit
      end
    else
      @project.errors.add(:base, "The email #{email} does not belong to any registered user.")
      render :edit
    end
  end

  def commit_logs
    @commit_logs = @project.commit_logs.order(created_at: :desc)
  end

  def show_commit_log
    @commit_log = @project.commit_logs.find(params[:id])
  end

  def toggle_favorite
    favorite = current_user.favorites.find_by(project: @project)

    if favorite
      favorite.destroy
      message = 'Project was removed from your favorites.'
    else
      current_user.favorites.create(project: @project)
      message = 'Project was added to your favorites.'
    end

    respond_to do |format|
      format.html { redirect_back(fallback_location: projects_path, notice: message) }
      format.js
    end
  end

  def favorite_projects
    @favorite_projects = current_user.favorite_projects.includes(:user)
  end

  def stats
    @unique_views = @project.unique_view_count
    @favorite_count = @project.favorite_count
  end

  def track_view
    return if ProjectView.exists?(project: @project, user: current_user)
    @project.project_views.create(user: current_user)
  end

  def update_permissions
    collaborator = Collaborator.find(params[:collaborator_id])

    if current_user == @project.user
      if collaborator.update(permissions: params[:permissions])
        redirect_to @project, notice: 'Collaborator permissions updated successfully.'
      else
        redirect_to @project, alert: 'Failed to update collaborator permissions.'
      end
    else
      redirect_to @project, alert: 'You are not authorized to update permissions.'
    end
  end

  def upload_to_google_drive
    require 'zip'
    callback_url = "http://127.0.0.1:3000/oauth2callback?project_id=#{@project.id}"

    client_id = Google::Auth::ClientId.new(ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'])
    token_store = Google::Auth::Stores::FileTokenStore.new(file: 'tokens.yaml')
    authorizer = Google::Auth::UserAuthorizer.new(client_id, Google::Apis::DriveV3::AUTH_DRIVE, token_store)

    user_id = current_user.email
    credentials = authorizer.get_credentials(user_id)

    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: callback_url)
      redirect_to url and return
    else
      begin
        session = GoogleDrive::Session.from_credentials(credentials)

        # Verifica se la cartella "CodePeer Projects" esiste, altrimenti creala
        folder = session.collection_by_title("CodePeer Projects")
        if folder.nil?
          folder = session.root_collection.create_subcollection("CodePeer Projects")
        end

        zipfile_name = "#{Rails.root}/tmp/#{@project.title}.zip"

        Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
          @project.project_files.each do |file|
            file_path = "#{Rails.root}/public/uploads/#{file.file}"
            zipfile.add(file.file_identifier, file_path) if File.exist?(file_path)
          end
        end

        folder.upload_from_file(zipfile_name, "#{@project.title}.zip", convert: false)

        redirect_to @project, notice: 'Project successfully uploaded to Google Drive.'
      rescue StandardError => e
        Rails.logger.error "Failed to upload to Google Drive: #{e.message}"
        redirect_to @project, alert: "Error during the upload process: #{e.message}"
      end
    end
  end

  def google_drive_auth
    project_id = params[:project_id] || session[:project_id]

    if project_id.blank?
      redirect_to projects_path, alert: "Project ID is missing."
      return
    end

    @project = Project.find(project_id)

    client_id = Google::Auth::ClientId.new(ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'])
    token_store = Google::Auth::Stores::FileTokenStore.new(file: 'tokens.yaml')
    authorizer = Google::Auth::UserAuthorizer.new(client_id, "https://www.googleapis.com/auth/drive", token_store)

    user_id = current_user.email

    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id,
      code: params[:code],
      base_url: "http://127.0.0.1:3000/oauth2callback"
    )

    # Invece di memorizzare l'intero oggetto credentials nella sessione, puoi memorizzare solo i dati necessari
    session[:google_credentials] = {
      access_token: credentials.access_token,
      refresh_token: credentials.refresh_token,
      expires_at: credentials.expires_at
    }

    redirect_to upload_to_google_drive_project_path(@project)
  end

  def upload_to_github
    @project = Project.find(params[:id])

    client = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
    repo = client.create_repository(@project.title.parameterize)

    @project.project_files.each do |file|
      file_path = "#{Rails.root}/public/uploads/#{file.file}"
      content = File.read(file_path)
      client.create_contents(repo.full_name, file.file_identifier, "Add #{file.file_identifier}", content)
    end

    redirect_to @project, notice: "Project uploaded to GitHub: #{repo.full_name}"
  end

  def upload_to_gitlab
    @project = Project.find(params[:id])

    client = Gitlab.client(endpoint: 'https://gitlab.com/api/v4', private_token: ENV['GITLAB_ACCESS_TOKEN'])
    gitlab_project = client.create_project(@project.title.parameterize)

    @project.project_files.each do |file|
      file_path = "#{Rails.root}/public/uploads/#{file.file}"
      if File.exist?(file_path)
        client.create_file(gitlab_project.id, file.file_identifier, 'master', File.read(file_path), commit_message: "Upload #{file.file_identifier}")
      end
    end

    redirect_to @project, notice: 'Project successfully uploaded to GitLab.'
  end

  def remove_collaborator
    @project = Project.find(params[:id])
    collaborator = @project.collaborators.find_by(user_id: params[:collaborator_id])

    if collaborator
      collaborator.destroy
      flash[:notice] = "Collaborator removed successfully."
    else
      flash[:alert] = "Collaborator not found."
    end

    redirect_to edit_project_path(@project)
  end

  def run_shell
    # Scarica i file del progetto da S3
    project_files_path = download_project_files_from_s3(@project)

    if project_files_path
      # Inizializza la shell nel container Docker
      ShellProcessManager.initialize_shell(@project, project_files_path)
    else
      flash[:error] = "Failed to download project files."
      redirect_to project_path(@project)
    end
  end

  private

  def set_project
    @project = Project.find(params[:id])
    session[:project_id] = @project.id
    unless @project.visibility == 'public' || @project.user == current_user || @project.collaborating_users.include?(current_user)
      redirect_to projects_path, alert: 'You are not authorized to access this project.'
    end
  end

  def project_params
    params.require(:project).permit(:title, :description, :visibility, project_files_attributes: [:id, :file, :_destroy])
  end

  def file_params
    params.require(:project_file).permit(:file)
  end

  def create_project_directory(project)
    s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'])
    bucket = s3.bucket(ENV['AWS_BUCKET'])
    user_folder_name = project.user.email.split('@').first
    project_folder_name = project.title.parameterize
    bucket.object("uploads/#{user_folder_name}/#{project_folder_name}/").put(body: "")
  end

  def send_collaborator_invitations
    emails = params[:collaborator_emails].split(',')
    permissions = params[:collaborator_permissions] # Prende i permessi dal form

    emails.each do |email|
      collaborator_user = User.find_by(email: email.strip)

      if collaborator_user
        collaborator = @project.collaborators.create!(user: collaborator_user, permissions: permissions)
        invitation = CollaboratorInvitation.create!(project: @project, user: collaborator_user, email: email.strip)

        if invitation.persisted?
          CollaboratorMailer.invite_email(invitation).deliver_now
        else
          Rails.logger.error "Failed to create invitation for #{email.strip}"
          raise ActiveRecord::Rollback
        end
      else
        @project.errors.add(:base, "The email #{email.strip} does not belong to any registered user.")
        raise ActiveRecord::Rollback
      end
    end
  end

  def execute_code_in_docker(code, language)
    docker_image = select_docker_image(language)
    file_extension = language_extension(language)

    Timeout.timeout(5) do  # Timeout di 5 secondi per l'esecuzione del codice
      Dir.mktmpdir do |dir|
        file_name = "main.#{file_extension}"
        file_path = File.join(dir, file_name)

        File.write(file_path, code, encoding: 'UTF-8')

        # Costruzione del comando Docker con restrizioni di sicurezza
        docker_cmd = [
          'docker', 'run', '--rm',
          '--network', 'none',                        # Disabilita l'accesso alla rete
          '--memory', '256m',                          # Limite di memoria
          '--cpus', '0.5',                             # Limite di CPU
          '--read-only',                               # Filesystem di sola lettura
          '-v', "#{dir}:/app:rw",                      # Monta la directory in modalità read-write
          '-w', '/app',
          docker_image
        ]

        # Comando specifico per il linguaggio
        language_cmd = case language
                       when 'python'
                         ["python3", file_name]
                       when 'c'
                         ["sh", "-c", "gcc -o main main.c && ./main"]
                       when 'cpp'
                         ["sh", "-c", "g++ -o main main.cpp && ./main"]
                       when 'java'
                         ["sh", "-c", "javac Main.java && java Main"]
                       when 'javascript'
                         ["node", file_name]
                       when 'ruby'
                         ["ruby", file_name]
                       when 'rust'
                         ["sh", "-c", "rustc main.rs && ./main"]
                       else
                         ["python3", file_name]
                       end

        full_command = docker_cmd + language_cmd

        # Esecuzione del comando e cattura di stdout, stderr e status
        stdout_str, stderr_str, status = Open3.capture3(*full_command)

        # Restituisce l'output, l'errore e lo status del comando
        [stdout_str, stderr_str, status]
      end
    end
  end

  def supported_language?(language)
    SUPPORTED_LANGUAGES.include?(language)
  end

  def select_docker_image(language)
    {
      'python'      => 'code-executor/python:latest',
      'c'           => 'code-executor/c:latest',
      'cpp'         => 'code-executor/cpp:latest',
      'javascript'  => 'code-executor/javascript:latest',
      'ruby'        => 'code-executor/ruby:latest',
      'java'        => 'code-executor/java:latest',
      'rust'        => 'code-executor/rust:latest'
    }.fetch(language, 'code-executor/python:latest')
  end

  def language_extension(language)
    {
      'python'      => 'py',
      'c'           => 'c',
      'cpp'         => 'cpp',
      'javascript'  => 'js',
      'ruby'        => 'rb',
      'java'        => 'java',
      'rust'        => 'rs'
    }.fetch(language, 'txt')
  end

  def read_file_content(file_path)
    File.read(file_path, encoding: 'UTF-8')
  end

  def calculate_diff(original_content, new_content)
    original_lines = original_content.split("\n")
    new_lines = new_content.split("\n")

    diff_lines = new_lines - original_lines
    diff_lines.join("\n")
  end

  def record_view
    return if ProjectView.exists?(project: @project, user: current_user)
    @project.project_views.create(user: current_user)
  end

  def authorized_to_edit?
    @project.user == current_user || @project.collaborating_users.include?(current_user)
  end
end
