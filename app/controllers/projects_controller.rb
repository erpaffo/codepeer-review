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
    @file_content = @file.file_content
  end

  def edit_file
    @file = @project.project_files.find(params[:file_id])
  end

  def update_file
    @file = @project.project_files.find(params[:file_id])
    if @file.update(file_params)
      redirect_to project_path(@project), notice: 'File was successfully updated.'
    else
      render :edit_file
    end
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
end
