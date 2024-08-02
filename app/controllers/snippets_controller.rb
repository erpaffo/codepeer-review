# app/controllers/snippets_controller.rb
class SnippetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_snippet, only: [:show, :edit, :update, :destroy, :toggle_favorite]

  def index
    @snippets = current_user.snippets
  end

  def new
    @snippet = Snippet.new
  end

  def create
    @snippet = Snippet.new(snippet_params)
    @snippet.user_id = current_user.id

    if @snippet.save
      redirect_to authenticated_root_path, notice: 'Snippet was successfully created.'
    else
      render :new
    end
  end

  def show
    @snippet
  end

  def edit
    @snippet
  end

  def update
    if @snippet.update(snippet_params)
      @snippet.save

      redirect_to snippet_path(@snippet), notice: 'Snippet was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @snippet.destroy
    redirect_to my_snippets_path, notice: 'Snippet was successfully deleted.'
  end

  def toggle_favorite
    @snippet.update(favorite: !@snippet.favorite)
    respond_to do |format|
      format.html { redirect_to my_snippets_path, notice: 'Snippet favorite status updated.' }
      format.json { render json: { favorite: @snippet.favorite } }
    end
  end

  private

  def set_snippet
    @snippet = Snippet.find(params[:id])
  end

  def snippet_params
    params.require(:snippet).permit(:title, :content, :comment, :favorite)
  end



end
