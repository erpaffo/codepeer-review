class Project < ApplicationRecord
  belongs_to :user
  has_many :project_files, dependent: :destroy
  accepts_nested_attributes_for :project_files

  validates :title, presence: true
  validates :description, presence: true
  validates :visibility, inclusion: { in: %w[private public] }
end
