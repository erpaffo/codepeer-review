class DashboardController < ApplicationController
  before_action :ensure_profile_complete

  def index
  end

  private

  def ensure_profile_complete
    redirect_to complete_profile_path unless current_user.profile_complete?
  end
end
