class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: [:show, :edit, :update, :destroy, :show_file, :edit_file, :update_file]

  def index
    @projects = current_user.projects
  end

  def show
  end

  def new
    @project = current_user.projects.build
    @project.project_files.build
  end

  def create
    @project = current_user.projects.build(project_params)
    if @project.save
      redirect_to @project, notice: 'Project was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: 'Project was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_url, notice: 'Project was successfully destroyed.'
  end

  def show_file
    @file = @project.project_files.find(params[:file_id])
    local_path = "#{Rails.root}/tmp/#{File.basename(@file.file.url)}"
    download_file_from_s3(ENV['AWS_BUCKET'], @file.file.path, local_path)
    @file_content = read_file_content(local_path)
    Rails.logger.debug "show_file: File content read from S3 - #{@file_content}"

    respond_to do |format|
      format.html
      format.json do
        Rails.logger.debug "show_file: File content sent as JSON - #{@file_content}"
        render json: { file_content: @file_content }
      end
    end
  end

  def edit_file
    @file = @project.project_files.find(params[:file_id])
    local_path = "#{Rails.root}/tmp/#{File.basename(@file.file.url)}"
    download_file_from_s3(ENV['AWS_BUCKET'], @file.file.path, local_path)
    @file_content = read_file_content(local_path)
    Rails.logger.debug "edit_file: File content read from S3 - #{@file_content}"

    respond_to do |format|
      format.html
      format.json do
        Rails.logger.debug "edit_file: File content sent as JSON - #{@file_content}"
        render json: { file_content: @file_content }
      end
    end
  end
  
  def update_file
    @file = @project.project_files.find(params[:file_id])
    new_file_content = params[:project_file][:file]
    Rails.logger.debug "update_file: New file content received from form - #{new_file_content}"

    # Converti il contenuto del file in UTF-8
    new_file_content_utf8 = new_file_content.encode('UTF-8')
    Rails.logger.debug "update_file: New file content encoded in UTF-8 - #{new_file_content_utf8}"

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

  private

  def set_project
    @project = current_user.projects.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:title, :description, project_files_attributes: [:id, :file, :_destroy])
  end

  def file_params
    params.require(:project_file).permit(:file)
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
    Rails.logger.debug "download_file_from_s3: File downloaded to local path - #{local_path}"
    local_path
  end

  def read_file_content(file_path)
    content = File.read(file_path, encoding: 'UTF-8')
    Rails.logger.debug "read_file_content: File content read - #{content}"
    content
  end
end
