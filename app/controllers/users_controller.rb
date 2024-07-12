# app/controllers/users_controller.rb
class UsersController < ApplicationController
  before_action :authenticate_user!

  def complete_profile
    @user = current_user
  end

  def update_profile
    @user = current_user
    if @user.update(user_params)
      handle_profile_image_update
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
      handle_profile_image_update
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
    params.require(:user).permit(:first_name, :last_name, :nickname, :phone_number, :otp_enabled, :profile_image_url, :remove_profile_image, :profile_image).dup
  end

  def remove_profile_image
    @user.profile_image.purge if @user.profile_image.attached?
  end

  def handle_profile_image_update
    if params[:user][:remove_profile_image] == '1'
      # Rimuovi l'immagine attualmente collegata e sostituiscila con white_image.png
      @user.profile_image.purge if @user.profile_image.attached?
      @user.profile_image.attach(io: File.open(Rails.root.join('app', 'assets', 'images', 'white_image.png')),
                                 filename: 'white_image.png',
                                 content_type: 'image/png')
      @user.update(profile_image_url: nil)  # Rimuove l'URL esterno se è stato sostituito con un file caricato
    elsif params[:user][:profile_image].present?
      # Aggiorna l'immagine del profilo con quella fornita nel parametro
      @user.profile_image.attach(params[:user][:profile_image])
      @user.update(profile_image_url: nil)  # Rimuove l'URL esterno se è stato sostituito con un file caricato
    end
  end

end
