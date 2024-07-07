class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: %i[show edit update destroy edit_file update_file]

  def index
    @projects = Project.all
  end

  def show
    # render project details and list of files
  end

  def new
    @project = Project.new
  end

  def edit
  end

  def create
    @project = Project.new(project_params)
    if @project.save
      create_readme_file(@project) if params[:project][:create_readme] == '1'
      redirect_to @project, notice: 'Project was successfully created.'
    else
      render :new
    end
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

  def edit_file
    @file = @project.files.find(params[:file_id])
    if ['.js', '.rb', '.py', '.md', '.c', '.cpp', '.rs', '.html', '.css', '.xml', '.txt'].include?(File.extname(@file.filename.to_s))
      @file_content = @file.download.force_encoding("UTF-8")
    else
      redirect_to project_path(@project), alert: 'Unsupported file type.'
    end
  end

  def update_file
    @file = @project.files.find(params[:file_id])
    if @file.present?
      @file.open do |f|
        f.write(params[:content])
      end
      redirect_to edit_file_project_path(@project, @file.id), notice: 'File was successfully updated.'
    else
      redirect_to project_path(@project), alert: 'File not found.'
    end
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:title, :description, files: [])
  end

  def create_readme_file(project)
    content = "# #{project.title}\n\n#{project.description}"
    readme = Tempfile.new(['README', '.md'])
    readme.write(content)
    readme.rewind
    project.files.attach(io: File.open(readme.path), filename: 'README.md', content_type: 'text/markdown')
  ensure
    readme.close
    readme.unlink
  end
end
