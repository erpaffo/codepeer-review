class AddFavoriteToSnippets < ActiveRecord::Migration[6.1]
  def change
    add_column :snippets, :favorite, :boolean
  end
end
