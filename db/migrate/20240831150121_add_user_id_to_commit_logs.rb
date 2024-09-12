class AddUserIdToCommitLogs < ActiveRecord::Migration[6.1]
  def change
    unless column_exists?(:commit_logs, :user_id)
      add_reference :commit_logs, :user, null: false, foreign_key: true
    end
  end
end
