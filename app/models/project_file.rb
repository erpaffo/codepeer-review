require 'open-uri'

class ProjectFile < ApplicationRecord
  belongs_to :project
  mount_uploader :file, FileUploader

  validates :file, presence: true

  def file_content
    open(file.url).read
  end
end
