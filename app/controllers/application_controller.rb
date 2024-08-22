class ApplicationController < ActionController::Base
  before_action :authenticate_user!, unless: :devise_controller?

  def after_sign_in_path_for(resource)
    if resource.otp_enabled?
      verify_otp_two_factor_auth_path
    elsif !resource.profile_complete?
      complete_profile_path
    else
      authenticated_root_path
    end
  end

  private

  def check_two_factor_auth
    return if !current_user || session[:otp_verified] || !current_user.otp_enabled?
    redirect_to new_two_factor_auth_path
  end
end
