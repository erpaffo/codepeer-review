class CommitLog < ApplicationRecord
  belongs_to :project
  belongs_to :file, class_name: 'ProjectFile'
  belongs_to :user

  validates :message, presence: true
end
