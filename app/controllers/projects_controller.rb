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
    @file_content = @file.file.read.force_encoding('UTF-8')
  end

  def edit_file
    @file = @project.project_files.find(params[:file_id])
    @file_content = @file.file.read.force_encoding('UTF-8')
  end

  def update_file
    @file = @project.project_files.find(params[:file_id])
    new_file_content = params[:project_file][:file]

    # Sovrascrivi il file su S3
    s3 = Aws::S3::Resource.new
    obj = s3.bucket(ENV['AWS_BUCKET']).object(@file.file.path)
    obj.put(body: new_file_content)

    redirect_to project_path(@project), notice: 'File was successfully updated.'
  end

  def run_code
    code = params[:code]
    language = params[:language]

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
                     'python:3.8'
                   # Aggiungere altri linguaggi se necessario
                   else
                     'python:3.8'
                   end

    command = "docker run --rm -i #{docker_image} python3 -c \"#{code}\""
    output = `#{command}`
    output
  end

  def read_and_format_file(file_path)
    content = File.read(file_path).force_encoding('UTF-8')
    formatted_content = content.gsub(/(?<!\\n)\n/, "\n")
    formatted_content
  end
end
