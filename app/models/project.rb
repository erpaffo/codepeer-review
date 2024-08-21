class Project < ApplicationRecord
  belongs_to :user
  has_many :project_files, dependent: :destroy
  has_many :collaborators, dependent: :destroy
  has_many :collaborating_users, through: :collaborators, source: :user
  has_many :collaborator_invitations, dependent: :destroy
  has_many :commit_logs, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorited_by_users, through: :favorites, source: :user
  has_many :project_views, dependent: :destroy

  after_create :award_badges

  accepts_nested_attributes_for :project_files

  validates :title, presence: true
  validates :description, presence: true
  validates :visibility, inclusion: { in: %w[private public] }

  validate :at_least_one_file

  def unique_view_count
    view_count = project_views.select(:user_id).distinct.count
    view_count += 1 if project_views.exists?(user: user)
    view_count
  end

  def favorite_count
    favorite_count = favorites.count
    favorite_count
  end

  private

  def at_least_one_file
    if project_files.empty?
      errors.add(:base, 'You must upload at least one file.')
    end
  end
  def award_badges
    user.check_and_award_badges("create_project")
  end
end
