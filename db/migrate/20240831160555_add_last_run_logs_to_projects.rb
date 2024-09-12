class AddLastRunLogsToProjects < ActiveRecord::Migration[6.1]
  def change
    add_column :projects, :last_run_logs, :text
  end
end
