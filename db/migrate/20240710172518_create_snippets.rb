class CreateSnippets < ActiveRecord::Migration[6.1]
  def change
    create_table :snippets do |t|
      t.string :title
      t.text :content
      t.text :comment
      t.integer :user_id, null: false
      t.references :project_file, null: false, foreign_key: true

      t