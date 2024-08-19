# app/models/history_record.rb
class HistoryRecord < ApplicationRecord
  belongs_to :snippet

  # Validazioni
  validates :field, presence: true
  validates :old_value, presence: true
  validates :new_value, presence: true
  validates :modified_by, presence: true # Facoltativo, se vuoi che questo campo sia obbligatorio

  # Trova il snippet precedente basato sulla cronologia
  def previous_snippet
    previous_record = self.class.where('snippet_id = ? AND created_at < ?', snippet_id, created_at)
                                .order(created_at: :desc)
                                .first
    previous_record ? previous_record.snippet : nil
  end
end
