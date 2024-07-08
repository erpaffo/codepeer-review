class TwoFactorAuthController < ApplicationController
  before_action :authenticate_user!

  def setup
  end

  def choose
    case params[:method]
    when 'sms'
      current_user.update(two_factor_method: 'sms')
      current_user.send_two_factor_authentication_code
      redirect_to sms_two_factor_auth_path
    when 'email'
      current_user.update(two_factor_method: 'email')
      current_user.send_two_factor_authentication_code
      redirect_to email_two_factor_auth_path
    when 'qr_code'
      current_user.update(two_factor_method: 'qr_code')
      current_user.generate_otp_secret
      redirect_to qr_code_two_factor_auth_path
    else
      redirect_to setup_two_factor_auth_path, alert: 'Invalid method selected'
    end
  end

  def sms
  end

  def email
  end

  def qr_code
    require 'rqrcode'

    @qr_code = RQRCode::QRCode.new(current_user.otp_provisioning_uri(current_user.email, issuer: 'YourApp')).as_png(size: 200).to_data_url
  end

  def verify
    if current_user.validate_and_consume_otp!(params[:otp_attempt])
      current_user.update(otp_required_for_login: true)
      redirect_to authenticated_root_path, notice: 'Two-Factor Authentication enabled'
    else
      redirect_to verify_otp_two_factor_auth_path, alert: 'Invalid code, please try again'
    end
  end

  def verify_otp
  end

  def send_backup_email
    current_user.send_two_factor_authentication_code('email')
    redirect_to verify_otp_two_factor_auth_path, notice: 'Backup email sent'
  end
end
