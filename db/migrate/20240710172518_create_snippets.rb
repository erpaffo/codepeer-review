class CreateSnippets < ActiveRecord::Migration[6.1]
  def change
    create_table :snippets do |t|
      t.string :title
      t.text :content
      t.text :comment
      t.integer :user_id, null: false

      t.timestamps
    end

    add_index :snippets, :user_id
  end
end
