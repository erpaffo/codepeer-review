# app/models/snippet.rb
class Snippet < ApplicationRecord

  belongs_to :user
  belongs_to :project_file, optional: true

  has_many :feedbacks, dependent: :destroy
  has_many :history_records, dependent: :destroy

  after_update :record_history

  # Definisci i linguaggi supportati come costante
  SUPPORTED_LANGUAGES = {
    '.rb' => 'Ruby',
    '.py' => 'Python',
    '.js' => 'JavaScript',
    '.html' => 'HTML',
    '.css' => 'CSS',
    '.c' => 'C'
    # aggiungi altre estensioni e linguaggi se necessario
  }.freeze

  # Validazioni
  validates :title, presence: true
  validates :content, presence: true
  validates :comment, presence: true
  validates :user_id, presence: true

  attribute :draft, :boolean, default: false

  before_save :set_language_from_title

  # Scope to fetch only drafts
  scope :drafts, -> { where(draft: true) }

  # Scope to fetch only published snippets
  scope :published, -> { where(draft: false) }

  # Metodo di classe per ottenere tutti i linguaggi disponibili
  def self.languages
    SUPPORTED_LANGUAGES.values.uniq
  end

  private

  # Imposta il linguaggio in base all'estensione del titolo
  def set_language_from_title
    self.language = language_from_extension
  end

  # Determina il linguaggio basato sull'estensione del titolo
  def language_from_extension
    return unless title.present?

    extension = File.extname(title).downcase
    SUPPORTED_LANGUAGES[extension] || 'Other'
  end

  def record_history
    changes.each do |field, (old_value, new_value)|
      next if old_value == new_value # Salta i campi che non sono cambiati

      history_records.create!(
        field: field,
        old_value: old_value,
        new_value: new_value
      )
    end
  end

end
