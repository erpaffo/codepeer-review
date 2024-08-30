class CreateCommitLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :commit_logs do |t|
      t.references :project, null: false, foreign_key: true
      t.references :file, null: false, foreign_key: { to_table: :project_files } 
      t.text :description
      t.text :diff
      t.timestamps
    end
  end
end
