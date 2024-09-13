require 'json'

class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[google_oauth2 github gitlab]

  validate :password_complexity
  validates :email, presence: true, uniqueness: true
  has_many :messages
  has_many :sent_conversations, class_name: 'Conversation', foreign_key: 'sender_id'
  has_many :received_conversations, class_name: 'Conversation', foreign_key: 'recipient_id'
  has_many :projects, dependent: :destroy
  has_many :notifications
  has_many :collaborators, dependent: :destroy
  has_many :collaborated_projects, through: :collaborators, source: :project
  has_many :snippets, dependent: :destroy
  has_many :feedbacks, dependent: :destroy
  has_many :received_feedbacks, class_name: 'Feedback', foreign_key: 'user_profile_id'
  has_many :follower_relationships, class_name: "Follow", foreign_key: "followed_id", dependent: :destroy
  has_many :followers, through: :follower_relationships, source: :follower
  has_many :following_relationships, class_name: "Follow", foreign_key: "follower_id", dependent: :destroy
  has_many :following, through: :following_relationships, source: :followed
  attribute :profile_image_url, :string
  has_many :favorites, dependent: :destroy
  has_many :favorite_projects, through: :favorites, source: :project
  has_many :user_badges
  has_many :badges, through: :user_badges

  attr_accessor :remove_profile_image

  after_create :create_user_directory

  has_one_attached :profile_image

  has_many :favorites, dependent: :destroy
  has_many :favorite_projects, through: :favorites, source: :project

  def toggle_favorite(project)
    if favorited?(project)
      favorite_projects.delete(project)
    else
      favorite_projects << project
    end
  end

  def name
    if nickname.present?
      nickname
    else
      [first_name, last_name].reject(&:blank?).join(' ')
    end
  end

  def conversations
    Conversation.where("sender_id = ? OR recipient_id = ?", id, id)
  end

  def favorited?(project)
    favorite_projects.include?(project)
  end

  def generate_otp_secret
    self.otp_secret ||= ROTP::Base32.random_base32
    save!
  end

  def profile_complete?
    first_name.present? && last_name.present? && nickname.present?
  end

  def check_and_award_badges(action)
    Badge.find_each do |badge|
      criteria = badge.criteria
      next unless criteria[:action] == action
      if meets_criteria?(badge)
        unless badges.include?(badge)
          badges << badge
          puts "Badge '#{badge.name}' assegnato!"
          Notification.create_badge_notification(self, badge, self)
        end
      else
        puts "Badge ID #{badge.id} non soddisfa i criteri."
      end
    end
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
    user = where(provider: auth.provider, uid: auth.uid).first_or_initialize do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20] + "Aa1@"
      user.first_name = auth.info.first_name || auth.info.name
      user.last_name = auth.info.last_name
      user.nickname = auth.info.nickname
      user.skip_confirmation!
      user.confirmed_at = Time.current
      user.profile_image_url = auth.info.image
    end

    if user.new_record?
      existing_user = find_by(email: auth.info.email)
      if existing_user
        existing_user.update(provider: auth.provider, uid: auth.uid)
        return existing_user
      end
    end

    user.update(nickname: auth.info.nickname) if auth.provider == 'github' && user.nickname.blank?
    user.update(first_name: auth.info.name) if auth.provider == 'google_oauth2' && user.first_name.blank?

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

  def follow(other_user)
    following_relationships.find_or_create_by(followed_id: other_user.id) unless self == other_user
  end

  def unfollow(other_user)
    relationship = following_relationships.find_by(followed_id: other_user.id)
    relationship&.destroy
  end

  def following?(user)
    following.include?(user)
  end

  def followed_by_current_user?(user)
    following.include?(user)
  end

  def two_factor_enabled?
    otp_required_for_login || two_factor_method.present?
  end

  def confirmation_required?
    Rails.env.test? ? false : super
  end

  # Aggiungi questa linea per confermare automaticamente l'utente
  after_create :confirm_user_if_test

  private

  def password_complexity
    return if password.blank? || password =~ /(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[[:^alnum:]])/
    errors.add :password, 'must include at least one lowercase letter, one uppercase letter, one digit, and one special character'
  end

  def create_user_directory
    s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'])
    bucket = s3.bucket(ENV['AWS_BUCKET'])
    user_folder_name = email.split('@').first
    bucket.object("uploads/#{user_folder_name}/").put(body: "")
  end

  def confirm_user_if_test
    confirm if Rails.env.test? && !confirmed?
  end

  def meets_criteria?(badge)
    criteria = badge.criteria
    case criteria[:action]
    when "create_project"
      projects.count >= criteria[:count]
    when "leave_feedback"
      feedbacks.count >= criteria[:count]
    else
      false
    end
  end
end
