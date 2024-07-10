require 'open-uri'

class ProjectFile < ApplicationRecord
  belongs_to :project
  mount_uploader :file, FileUploader

  validates :file, presence: true

  before_update :create_snippet
  has_many :snippets, dependent: :destroy

  def file_content
    open(file.url).read
  end

  private

  def create_snippet
    original_content = self.file.read.force_encoding('UTF-8').split("\n")
    new_content = self.file.file.read.split("\n") # assuming `file` attribute holds the new content
    snippet_content = (new_content - original_content).join("\n")
    self.snippets.create(content: snippet_content)
  end
end
