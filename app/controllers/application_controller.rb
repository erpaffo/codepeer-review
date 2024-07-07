class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :check_two_factor_auth

  private

  def check_two_factor_auth
    return if !current_user || session[:otp_verified] || !current_user.otp_enabled?

    redirect_to new_two_factor_auth_path
  end
end
