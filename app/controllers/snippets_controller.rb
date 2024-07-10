class SnippetsController < ApplicationController
  before_action :set_project_file

  def create
    @snippet = @project_file.snippets.new(snippet_params)
    if @snippet.save
      redirect_to project_project_file_snippet_path(@project_file.project, @project_file, @snippet), notice: 'Snippet was successfully created.'
    else
      render :new
    end
  end

  def show
    @snippet = @project_file.snippets.find(params[:id])
  end

  private

  def set_project_file
    @project_file = ProjectFile.find(params[:project_file_id])
  end

  def snippet_params
    params.require(:snippet).permit(:content)
  end
end
