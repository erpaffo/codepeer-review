# app/models/user_badge.rb
class UserBadge < ApplicationRecord
  belongs_to :user
  belongs_to :badge
end
