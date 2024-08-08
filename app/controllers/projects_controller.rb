class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [:show, :edit, :update, :destroy, :show_file, :edit_file, :update_file, :new_file, :create_file]

  def index
    @projects = Project.where("visibility = ? OR user_id = ?", 'public', current_user.id)
  end

  def show
    if @project.visibility == 'private' && @project.user != current_user
      redirect_to projects_path, alert: 'You are not authorized to view this project.'
    end
  end

  def new
    @project = current_user.projects.build
    @project.project_files.build
  end

  def create
    @project = current_user.projects.build(project_params)
    if @project.save
      create_project_directory(@project)  # Creare la cartella del progetto su AWS S3
      redirect_to @project, notice: 'Project was successfully created.'
    else
      render :new
    end
  end

  def edit
    if @project.user != current_user
      redirect_to projects_path, alert: 'You are not authorized to edit this project.'
    end
  end

  def update
    if @project.user != current_user
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

    # Converti il contenuto del file in UTF-8
    new_file_content_utf8 = new_file_content.encode('UTF-8')

    # Ottieni il contenuto originale del file
    local_path = "#{Rails.root}/tmp/#{File.basename(@file.file.url)}"
    download_file_from_s3(ENV['AWS_BUCKET'], @file.file.path, local_path)
    original_file_content = read_file_content(local_path)

    # Calcola la differenza tra il contenuto originale e quello nuovo
    snippet_content = calculate_diff(original_file_content, new_file_content_utf8)

    # Crea un nuovo snippet con la differenza
    @file.snippets.create(content: snippet_content)

    # Sovrascrivi il file su S3
    s3 = Aws::S3::Resource.new
    obj = s3.bucket(ENV['AWS_BUCKET']).object(@file.file.path)
    obj.put(body: new_file_content_utf8)

    redirect_to project_path(@project), notice: 'File was successfully updated.'
  end

  def run_code
    code = params[:code]
    language = params[:language]
    bucket = ENV['AWS_BUCKET']
    key = params[:file_key]

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

    File.open(file_path, "w") {} # Crea un file vuoto

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


  private

  def set_project
    @project = current_user.projects.find(params[:id])
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
    # Creare una cartella vuota (un oggetto con un '/' finale)
    bucket.object("uploads/#{user_folder_name}/#{project_folder_name}/").put(body: "")
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
end
