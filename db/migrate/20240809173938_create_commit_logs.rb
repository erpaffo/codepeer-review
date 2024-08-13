class CreateCommitLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :commit_logs do |t|
      t.references :project, null: false, foreign_key: true
      t.text :description
      t.timestamps
    end
  end
end
