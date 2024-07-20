# app/models/snippet.rb
class Snippet < ApplicationRecord
  belongs_to :user

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

  before_save :set_language_from_title

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
end
