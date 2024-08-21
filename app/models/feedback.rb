# app/models/feedback.rb
class Feedback < ApplicationRecord
  belongs_to :user
  belongs_to :snippet, optional: true
  belongs_to :user_profile, class_name: 'User', optional: true

  after_create :award_badges

  validates :content, presence: true
  validates :user_id, presence: true

private

  def award_badges
    user.check_and_award_badges("leave_feedback")
  end
end
