class SearchController < ApplicationController
  def index
  end

  def results
    query = params[:query]
    @users = User.where('nickname LIKE ?', "%#{query}%")
    @projects = Project.where('title LIKE ?', "%#{query}%").where(visibility: 'public')
    @snippets = Snippet.where('title LIKE ?', "%#{query}%").where(draft: false)
    @privateprojects = Project.where('title LIKE ?', "%#{query}%").where(visibility: 'private')
  end
end
