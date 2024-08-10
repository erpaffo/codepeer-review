class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [:show, :edit, :update, :destroy, :show_file, :edit_file, :update_file, :new_file, :create_file, :commit_logs, :toggle_favorite, :stats, :update_permissions]

  def index
    @projects = current_user.projects + current_user.collaborated_projects
  end

  def show
    if @project.visibility == 'private' && @project.user != current_user && !@project.collaborating_users.include?(current_user)
      redirect_to projects_path, alert: 'You are not authorized to view this project.'
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
        redirect_to @project, notice: 'Project was successfully created.'
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

  def edit
    if @project.user != current_user && !@project.collaborating_users.include?(current_user)
      redirect_to projects_path, alert: 'You are not authorized to edit this project.'
    end
  end

  def update
    if @project.user != current_user && !@project.collaborating_users.include?(current_user)
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
    if @project.user != current_user
      redirect_to projects_path, alert: 'You are not authorized to delete this project.'
    else
      @project.destroy
      redirect_to projects_url, notice: 'Project was successfully destroyed.'
    end
  end

  def show_file
    @file = @project.project_files.find(params[:file_id])
    local_path = "#{Rails.root}/tmp/#{File.basename(@file.file.url)}"
    download_file_from_s3(ENV['AWS_BUCKET'], @file.file.path, local_path)
    @file_content = read_file_content(local_path)

    respond_to do |format|
      format.html
      format.json { render json: { file_content: @file_content } }
    end
  end

  def edit_file
    @file = @project.project_files.find(params[:file_id])
    local_path = "#{Rails.root}/tmp/#{File.basename(@file.file.url)}"
    download_file_from_s3(ENV['AWS_BUCKET'], @file.file.path, local_path)
    @file_content = read_file_content(local_path)

    respond_to do |format|
      format.html
      format.json { render json: { file_content: @file_content } }
    end
  end

  def update_file
    @file = @project.project_files.find(params[:file_id])
    new_file_content = params[:project_file][:file]

    new_file_content_utf8 = new_file_content.encode('UTF-8')

    local_path = "#{Rails.root}/tmp/#{File.basename(@file.file.url)}"
    download_file_from_s3(ENV['AWS_BUCKET'], @file.file.path, local_path)
    original_file_content = read_file_content(local_path)

    snippet_content = calculate_diff(original_file_content, new_file_content_utf8)

    @file.snippets.create(content: snippet_content)

    s3 = Aws::S3::Resource.new
    obj = s3.bucket(ENV['AWS_BUCKET']).object(@file.file.path)
    obj.put(body: new_file_content_utf8)

    redirect_to project_path(@project), notice: 'File was successfully updated.'
  end

  def run_code
    code = params[:code]
    language = params[:language]

    output = execute_code_in_docker(code, language)

    render json: { output: output }
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

  private

  def set_project
    @project = Project.find(params[:id])
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
    docker_image = case language
                   when 'python'
                     'python:3.8-slim'
                   when 'c'
                     'gcc:latest'
                   when 'java'
                     'openjdk:11'
                   when 'javascript'
                     'node:14'
                   when 'ruby'
                     'ruby:latest'
                   when 'go'
                     'golang:latest'
                   when 'php'
                     'php:latest'
                   when 'swift'
                     'swift:latest'
                   when 'kotlin'
                     'openjdk:11'
                   when 'rust'
                     'rust:latest'
                   else
                     'python:3.8-slim'
                   end

    Dir.mktmpdir do |dir|
      file_name = "main.#{language_extension(language)}"
      file_path = "#{dir}/#{file_name}"

      File.write(file_path, code, encoding: 'UTF-8')

      command = case language
                when 'python'
                  "docker run --rm -v #{dir}:/app -w /app #{docker_image} python3 #{file_name}"
                when 'c'
                  "docker run --rm -v #{dir}:/app -w /app #{docker_image} sh -c 'gcc -o main main.c && ./main'"
                when 'java'
                  "docker run --rm -v #{dir}:/app -w /app #{docker_image} sh -c 'javac Main.java && java Main'"
                when 'javascript'
                  "docker run --rm -v #{dir}:/app -w /app #{docker_image} node #{file_name}"
                when 'ruby'
                  "docker run --rm -v #{dir}:/app -w /app #{docker_image} ruby #{file_name}"
                when 'go'
                  "docker run --rm -v #{dir}:/app -w /app #{docker_image} sh -c 'go build -o main main.go && ./main'"
                when 'php'
                  "docker run --rm -v #{dir}:/app -w /app #{docker_image} php #{file_name}"
                when 'swift'
                  "docker run --rm -v #{dir}:/app -w /app #{docker_image} sh -c 'swiftc -o main main.swift && ./main'"
                when 'kotlin'
                  "docker run --rm -v #{dir}:/app -w /app #{docker_image} sh -c 'kotlinc main.kt -include-runtime -d main.jar && java -jar main.jar'"
                when 'rust'
                  "docker run --rm -v #{dir}:/app -w /app #{docker_image} sh -c 'rustc main.rs && ./main'"
                else
                  "docker run --rm -v #{dir}:/app -w /app #{docker_image} python3 #{file_name}"
                end

      output = `#{command}`
      output
    end
  end

  def language_extension(language)
    case language
    when 'python'
      'py'
    when 'c'
      'c'
    when 'java'
      'java'
    when 'javascript'
      'js'
    when 'ruby'
      'rb'
    when 'go'
      'go'
    when 'php'
      'php'
    when 'swift'
      'swift'
    when 'kotlin'
      'kt'
    when 'rust'
      'rs'
    else
      'txt'
    end
  end

  def download_file_from_s3(bucket, key, local_path)
    s3 = Aws::S3::Client.new(region: ENV['AWS_REGION'])
    File.open(local_path, 'wb') do |file|
      s3.get_object(bucket: bucket, key: key) do |chunk|
        file.write(chunk)
      end
    end
    local_path
  end

  def read_file_content(file_path)
    content = File.read(file_path, encoding: 'UTF-8')
    content
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
end
