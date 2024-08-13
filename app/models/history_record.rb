# app/models/history_record.rb
class HistoryRecord < ApplicationRecord
  belongs_to :snippet

  validates :field, presence: true
  validates :old_value, presence: true
  validates :new_value, presence: true
end
