class DashboardController < ApplicationController
  before_action :ensure_profile_complete

  def index
    @all_projects = (current_user.projects + current_user.collaborated_projects + Project.where(visibility: 'public')).uniq
  end

  private

  def ensure_profile_complete
    redirect_to complete_profile_path unless current_user.profile_complete?
  end
end
