class ProjectFile < ApplicationRecord
  belongs_to :project

  mount_uploader :file, FileUploader

  validates :file, presence: true

  before_update :create_snippet
  before_create :set_file_name
  after_save :create_commit_log

  has_many :snippets, dependent: :destroy

  def file_content
    open(file.url).read
  end

  private

  def create_snippet
    original_content = self.file.read.force_encoding('UTF-8').split("\n")
    new_content = self.file.file.read.split("\n")
    snippet_content = (new_content - original_content).join("\n")
    self.snippets.create(content: snippet_content)
  end

  def set_file_name
    if self.file.blank?
      self.file = File.open("#{Rails.root}/tmp/#{file_identifier}")
    end
  end

  def create_commit_log
    return unless saved_changes?

    message = if saved_changes.key?('id')
                "File '#{file.filename}' was created."
              else
                "File '#{file.filename}' was updated. Changes:\n#{generate_diff}"
              end

    self.project.commit_logs.create(message: message)
  end


  def generate_diff
    original_content = self.file.read.force_encoding('UTF-8').split("\n")
    new_content = self.file.file.read.split("\n")
    diff = Diffy::Diff.new(original_content.join("\n"), new_content.join("\n")).to_s(:text)
    diff
  end
end
