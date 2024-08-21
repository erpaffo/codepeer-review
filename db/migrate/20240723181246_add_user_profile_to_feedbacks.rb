class AddUserProfileToFeedbacks < ActiveRecord::Migration[6.1]
  def change
   # add_reference :feedbacks, :user_profile, null: true, foreign_key: { to_table: :users }
  end
end
