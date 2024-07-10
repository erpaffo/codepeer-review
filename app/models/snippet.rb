class Snippet < ApplicationRecord
  belongs_to :project_file

  validates :content, presence: true
end
