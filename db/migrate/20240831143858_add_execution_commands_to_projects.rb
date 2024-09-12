class AddExecutionCommandsToProjects < ActiveRecord::Migration[6.1]
  def change
    add_column :projects, :execution_commands, :text, default: nil
  end
end
