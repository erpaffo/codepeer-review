class AddUserIdAndMessageToCommitLogs < ActiveRecord::Migration[6.1]
  def change
    add_reference :commit_logs, :user, foreign_key: true
    add_column :commit_logs, :message, :string
  end
end
