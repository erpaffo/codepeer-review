class CommitLog < ApplicationRecord
  belongs_to :project
  belongs_to :user
  has_many :commit_files, dependent: :destroy

end
