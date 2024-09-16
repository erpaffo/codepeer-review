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
  after_save :detect_languages, if: :project_files_changed?

  accepts_nested_attributes_for :project_files

  validates :title, presence: true
  validates :description, presence: true
  validates :visibility, inclusion: { in: %w[private public] }

  # Metodo per il conteggio delle visualizzazioni uniche
  def unique_view_count
    view_count = project_views.select(:user_id).distinct.count
    view_count += 1 if project_views.exists?(user: user)
    view_count
  end

  # Metodo per il conteggio dei favoriti
  def favorite_count
    favorites.count
  end

  # Rilevare automaticamente i linguaggi usati nel progetto
  def detect_languages
    detector = LanguageDetector.new(self)
    detected_languages = detector.detect_languages

    # Aggiorna il campo languages con i linguaggi rilevati
    update_column(:languages, detected_languages)
  end
  
  private

  # Assicurarsi che ci sia almeno un file nel progetto
  def at_least_one_file
    if project_files.empty?
      errors.add(:base, 'You must upload at least one file.')
    end
  end

  # Assegnare badge all'utente
  def award_badges
    user.check_and_award_badges("create_project")
  end

  # Verificare se i file del progetto sono cambiati
  def project_files_changed?
    project_files.any?(&:changed?)
  end

end
