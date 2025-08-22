class ApplicationController < ActionController::Base
  before_action :force_ssl_in_production
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!, unless: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :email, :password, :password_confirmation])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username, :email, :password, :password_confirmation, :current_password])
  end

  private

  def force_ssl_in_production
    if Rails.env.production? && !request.ssl?
      redirect_to protocol: 'https://', status: :moved_permanently
    end
  end

  def after_sign_in_path_for(resource)
    if resource.otp_enabled?
      verify_otp_two_factor_auth_path
    elsif !resource.profile_complete?
      complete_profile_path
    else
      authenticated_root_path
    end
  end

  def check_two_factor_auth
    return if !current_user || session[:otp_verified] || !current_user.otp_enabled?
    redirect_to new_two_factor_auth_path
  end
end
