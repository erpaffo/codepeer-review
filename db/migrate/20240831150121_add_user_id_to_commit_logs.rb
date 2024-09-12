class AddUserIdToCommitLogs < ActiveRecord::Migration[6.1]
  def change
    add_reference :commit_logs, :user, null: false, foreign_key: true
  end
end
