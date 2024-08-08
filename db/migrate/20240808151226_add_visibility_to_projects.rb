class AddVisibilityToProjects < ActiveRecord::Migration[6.1]
  def change
    add_column :projects, :visibility, :string, default: 'private'
  end
end
