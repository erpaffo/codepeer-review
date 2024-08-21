class AddModifiedByToHistoryRecords < ActiveRecord::Migration[6.1]
  def change
    add_column :history_records, :modified_by, :string
  end
end
