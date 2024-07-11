class UsersController < ApplicationController
  before_action :authenticate_user!

  def complete_profile
    @user = current_user
  end

  def update_profile
    @user = current_user
    if @user.update(user_params)
      remove_profile_image if params[:user][:remove_profile_image] == '1'
      redirect_to authenticated_root_path, notice: 'Profile updated successfully'
    else
      render :complete_profile
    end
  end

  def show
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(user_params)
      remove_profile_image if params[:user][:remove_profile_image] == '1'
      @user.generate_otp_secret if @user.otp_enabled_changed? && @user.otp_enabled
      @user.send_two_factor_authentication_code if @user.otp_enabled
      redirect_to authenticated_root_path, notice: 'Profile updated successfully'
    else
      render :edit
    end
  end

  def enable_two_factor_auth
    current_user.update(otp_enabled: true)
    current_user.generate_otp_secret
    current_user.send_two_factor_authentication_code
    redirect_to authenticated_root_path, notice: 'Two-Factor Authentication enabled'
  end

  def disable_two_factor_auth
    current_user.update(otp_enabled: false, otp_secret: nil)
    redirect_to authenticated_root_path, notice: 'Two-Factor Authentication disabled'
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :nickname, :phone_number, :otp_enabled, :profile_image, :remove_profile_image)
  end

  def remove_profile_image
    @user.profile_image.purge if @user.profile_image.attached?
  end
end
