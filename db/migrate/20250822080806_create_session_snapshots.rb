class CreateSessionSnapshots < ActiveRecord::Migration[7.1]
  def change
    create_table :session_snapshots do |t|
      t.references :user, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :file_count, default: 0
      t.bigint :archive_size, default: 0

      t.timestamps
    end
    
    add_index :session_snapshots, [:user_id, :project_id]
    add_index :session_snapshots, [:project_id, :created_at]
  end
end
