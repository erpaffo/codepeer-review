class AddNotifierIdToNotifications < ActiveRecord::Migration[6.1]
  def change
    unless column_exists?(:notifications, :notifier_id)
      add_column :notifications, :notifier_id, :integer
      add_index :notifications, :notifier_id
    end
  end
end
