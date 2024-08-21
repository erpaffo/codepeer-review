class CreateFeedbacks < ActiveRecord::Migration[6.1]
  def change
    create_table :feedbacks do |t|
      t.text :content
      t.references :user, null: false, foreign_key: true
      t.references :snippet, null: true, foreign_key: true
      t.references :user_profile, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end

