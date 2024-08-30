class AddUserIdAndMessageToCommitLogs < ActiveRecord::Migration[6.1]
  def change
    add_column :commit_logs, :message, :string
  end
end
