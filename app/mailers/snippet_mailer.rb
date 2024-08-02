class SnippetMailer < ApplicationMailer
  def share_snippet
    @snippet = params[:snippet]
    mail(to: params[:email], subject: 'Ecco uno snippet che potrebbe interessarti!')
  end
end
