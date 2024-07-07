class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable,
         :omniauthable, omniauth_providers: %i[google_oauth2 github gitlab]

  def generate_otp_secret
    self.otp_secret = ROTP::Base32.random_base32
    save
  end

  def send_two_factor_authentication_code
    client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
    client.messages.create(
      from: ENV['TWILIO_PHONE_NUMBER'],
      to: phone_number,
      body: "Your verification code is: #{otp_code}"
    )
  end

  def otp_code
    ROTP::TOTP.new(otp_secret).now
  end

  def validate_and_consume_otp!(code)
    totp = ROTP::TOTP.new(otp_secret)
    return totp.verify(code, drift_ahead: 30, drift_behind: 30)
  end

  def self.from_omniauth(auth)
    user = User.where(email: auth.info.email).first

    if user
      # Aggiorna l'account esistente con le nuove informazioni di OAuth
      user.update(provider: auth.provider, uid: auth.uid)
    else
      # Crea un nuovo account
      user = User.create(
        provider: auth.provider,
        uid: auth.uid,
        email: auth.info.email,
        password: Devise.friendly_token[0, 20],
        first_name: auth.info.first_name || auth.info.name,
        last_name: auth.info.last_name,
        nickname: auth.info.nickname
      )
    end
    user
  end
end
