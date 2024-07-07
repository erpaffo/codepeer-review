class TwoFactorAuthController < ApplicationController
  before_action :authenticate_user!

  def new
  end

  def create
    if current_user.otp_code == params[:otp_code]
      session[:otp_verified] = true
      redirect_to authenticated_root_path, notice: 'Successfully authenticated with 2FA'
    else
      flash[:alert] = 'Invalid verification code'
      render :new
    end
  end
end
