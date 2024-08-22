class AddNotifierIdToNotifications < ActiveRecord::Migration[6.1]
  def change
    add_column :notifications, :notifier_id, :integer
    add_index :notifications, :notifier_id
  end
end
