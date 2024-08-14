class SnippetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_snippet, only: [:show, :edit, :update, :destroy, :toggle_favorite, :make_public]

  # Mostra solo snippet pubblici per l'utente
  def index
    @snippets = current_user.snippets.where(draft: false) # Solo snippet pubblici
  end

  def new
    @snippet = Snippet.new
  end

  def create
    @snippet = Snippet.new(snippet_params)
    @snippet.user_id = current_user.id
    @snippet.project_file_id = snippet_params[:project_file_id].presence

    if params[:save_as_draft]
      @snippet.draft = true
      notice_message = 'Snippet was successfully saved as a draft.'
    else
      @snippet.draft = false
      notice_message = 'Snippet was successfully created.'
    end

    if @snippet.save
      if @snippet.draft
        redirect_to my_snippets_path, notice: notice_message
      else
        redirect_to my_snippets_path, notice: notice_message
      end
    else
      render :new
    end
  end

  def show
    # @snippet è già impostato dal before_action
  end

  def show_from_profile
    @snippet = Snippet.find(params[:id])
    @user = @snippet.user
  end

  def edit
    # @snippet è già impostato dal before_action
  end

  def update
    if @snippet.update(snippet_params)
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

  def drafts
    @languages = Snippet.languages
    @drafts = current_user.snippets.where(draft: true) # Solo bozze

    # Ordinamento
    if params[:order_by] == 'most_recent'
      @drafts = @drafts.order(created_at: :desc)
    elsif params[:order_by] == 'least_recent'
      @drafts = @drafts.order(created_at: :asc)
    elsif params[:order_by] == 'favorites'
      @drafts = @drafts.order(favorite: :desc, created_at: :desc)
    end

    # Filtro per lingua
    if params[:language] == 'other'
      @drafts = @drafts.where.not(language: Snippet.languages)
    elsif params[:language].present?
      @drafts = @drafts.where(language: params[:language])
    end
  end

  def make_public
    if @snippet && @snippet.user == current_user
      @snippet.update(draft: false)
      redirect_to snippet_path(@snippet), notice: 'Snippet has been made public.'
    else
      redirect_to drafts_snippets_path, alert: 'Snippet not found or unauthorized access.'
    end
  end

  private

  def set_snippet
    @snippet = Snippet.find_by(id: params[:id])
  end

  def snippet_params
    params.require(:snippet).permit(:title, :content, :comment, :favorite, :project_file_id)
  end
end
