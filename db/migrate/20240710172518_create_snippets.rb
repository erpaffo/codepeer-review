class CreateSnippets < ActiveRecord::Migration[6.1]
  def change
    create_table :snippets do |t|
      t.references :project_file, null: false, foreign_key: true
      t.text :content

      t.timestamps
    end
  end
end
