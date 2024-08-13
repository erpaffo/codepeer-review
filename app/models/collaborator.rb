class Collaborator < ApplicationRecord
  belongs_to :user
  belongs_to :project

  PERMISSIONS = ['full', 'partial'].freeze

  validates :permissions, inclusion: { in: PERMISSIONS }
  validates :user, presence: true
end
