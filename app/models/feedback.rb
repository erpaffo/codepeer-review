class Feedback < ApplicationRecord
  belongs_to :user
  belongs_to :snippet, optional: true
  belongs_to :user_profile, class_name: 'User', optional: true
  
  validates :content, presence: true
  validates :user_id, presence: true
  validates :snippet_id, presence: true
end
