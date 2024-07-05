# app/controllers/projects_controller.rb

class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project, only: %i[show edit update destroy]

  def index
    @projects = Project.all
  end

  def show
  end

  def new
    @project = Project.new
  end

  def edit
  end

  def create
    @project = current_user.projects.new(project_params)  # Associare il progetto all'utente corrente
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
