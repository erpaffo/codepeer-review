# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[google_oauth2 github gitlab]

  validate :password_complexity
  has_many :projects, dependent: :destroy
  attribute :profile_image_url, :string
  attr_accessor :remove_profile_image

  has_one_attached :profile_image

  def generate_otp_secret
    self.otp_secret ||= ROTP::Base32.random_base32
    save!
  end

  def send_two_factor_authentication_code(method = nil)
    method ||= two_factor_method
    generate_otp_secret if otp_secret.nil?
    if method == 'sms'
      if phone_number.present?
        client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
        client.messages.create(
          from: ENV['TWILIO_PHONE_NUMBER'],
          to: phone_number,
          body: "Your verification code is: #{otp_code}"
        )
      else
        errors.add(:base, 'Phone number is missing')
        throw(:abort)
      end
    elsif method == 'email'
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
    label = "#{issuer}:#{account}"
    totp = ROTP::TOTP.new(otp_secret, issuer: issuer)
    totp.provisioning_uri(label)
  end

  def self.from_omniauth(auth)
    user = where(provider: auth.provider, uid: auth.uid).first_or_initialize do |u|
      u.email = auth.info.email
      u.skip_confirmation!
      u.confirmed_at = Time.current # Conferma automatica dell'utente
    end

    unless user.persisted?
      user.password = Devise.friendly_token[0, 20] unless user.encrypted_password.present?
    end

    if auth.info
      user.nickname = auth.info.nickname
      user.first_name = auth.info.first_name || auth.info.name
      user.profile_image_url = auth.info.image # Assicurati che 'image' sia il campo corretto per l'URL dell'immagine
    end

    user.save!
    user
  end

  def profile_image_url
    if super.present?
      super
    else
      ActionController::Base.helpers.asset_url('white_image.png')
    end
  end

  private

  def password_complexity
    return if password.blank? || password =~ /(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[[:^alnum:]])/

    errors.add :password, 'must include at least one lowercase letter, one uppercase letter, one digit, and one special character'
  end
end
