class AddUserIdToMessages < ActiveRecord::Migration[6.1]
  def change
    unless column_exists?(:messages, :user_id)
      add_column :messages, :user_id, :integer
    end
  end
end
