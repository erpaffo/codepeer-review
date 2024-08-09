class AddFavoriteToProjects < ActiveRecord::Migration[6.1]
  def change
    add_column :projects, :favorite, :boolean
  end
end
