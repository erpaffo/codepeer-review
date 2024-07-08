class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[google_oauth2 github gitlab]

  attr_accessor :otp_attempt

  def generate_otp_secret
    self.otp_secret ||= ROTP::Base32.random_base32
    save!
  end

  def send_two_factor_authentication_code(method = nil)
    method ||= two_factor_method
    generate_otp_secret if otp_secret.nil?
    if method == 'sms'
      # Inviare il codice via SMS
      client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
      client.messages.create(
        from: ENV['TWILIO_PHONE_NUMBER'],
        to: phone_number,
        body: "Your verification code is: #{otp_code}"
      )
    elsif method == 'email'
      # Inviare il codice via email
      UserMailer.two_factor_auth_code(self).deliver_now
    end
  end

  def otp_code
    ROTP::TOTP.new(otp_secret).now
  end

  def validate_and_consume_otp!(code)
    totp = ROTP::TOTP.new(otp_secret)
    totp.verify(code, drift_ahead: 30, drift_behind: 30)
  end

  def otp_provisioning_uri(account = email, issuer = 'YourApp')
    totp = ROTP::TOTP.new(otp_secret, issuer: issuer)
    totp.provisioning_uri(account)
  end

  def self.from_omniauth(auth)
    user = where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.first_name = auth.info.first_name || auth.info.name
      user.last_name = auth.info.last_name
      user.nickname = auth.info.nickname
      user.skip_confirmation!
      user.confirmed_at = Time.current # Conferma automatica dell'utente
    end

    user.update(nickname: auth.info.nickname) if auth.provider == 'github' && user.nickname.blank?
    user.update(first_name: auth.info.name) if auth.provider == 'google_oauth2' && user.first_name.blank?
    user
  end
end
