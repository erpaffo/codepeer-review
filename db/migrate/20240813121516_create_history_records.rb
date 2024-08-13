class CreateHistoryRecords < ActiveRecord::Migration[6.1]
  def change
    create_table :history_records do |t|
      t.references :snippet, null: false, foreign_key: true
      t.string :field
      t.string :old_value
      t.string :new_value

      t.timestamps
    end
  end
end
