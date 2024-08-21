class Badge < ApplicationRecord
  has_many :user_badges
  has_many :users, through: :user_badges

  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :icon, presence: true
  serialize :criteria, Hash
end
