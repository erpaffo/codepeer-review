class SearchController < ApplicationController
  def index
  end

  def results
    query = params[:query]
    @users = User.where('nickname LIKE ?', "%#{query}%")
    @projects = Project.where('title LIKE ?', "%#{query}%").where(visibility: 'public')
  end
end
