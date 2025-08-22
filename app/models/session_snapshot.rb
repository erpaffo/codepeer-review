class SessionSnapshot < ApplicationRecord
  belongs_to :user
  belongs_to :project
  
  has_one_attached :workspace_archive
  
  validates :name, presence: true
  validates :description, length: { maximum: 500 }
  
  scope :for_user, ->(user) { where(user: user) }
  scope :for_project, ->(project) { where(project: project) }
  scope :recent, -> { order(created_at: :desc) }
  
  def filename
    "workspace_#{id}.tar.gz"
  end
  
  def display_name
    name.presence || "Snapshot #{created_at.strftime('%Y-%m-%d %H:%M')}"
  end
end
