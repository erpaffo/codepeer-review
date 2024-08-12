class ChangeProjectFileIdInSnippets < ActiveRecord::Migration[6.0]
  def change
    change_column :snippets, :project_file_id, :integer, null: true
  end
end
