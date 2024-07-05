# app/models/project.rb

class Project < ApplicationRecord
  belongs_to :user
  has_many_attached :files

  validates :title, presence: true
  validates :description, presence: true
end
