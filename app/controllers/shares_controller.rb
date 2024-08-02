class SharesController < ApplicationController
  before_action :set_snippet, only: [:new, :create]

  def new
    @recipient_email = ''
  end

  def create
    recipient_email = params[:email]
    SnippetMailer.with(snippet: @snippet, email: recipient_email).share_snippet.deliver_now
    redirect_to snippet_path(@snippet), notice: 'Snippet condiviso con successo!'
  end

  private

  def set_snippet
    @snippet = Snippet.find(params[:id])
  end
end
