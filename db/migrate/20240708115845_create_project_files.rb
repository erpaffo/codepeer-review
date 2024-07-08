class CreateProjectFiles < ActiveRecord::Migration[6.1]
  def change
    create_table :project_files do |t|
      t.references :project, null: false, foreign_key: true
      t.string :file

      t.timestamps
    end
  end
end
