class AddLanguageToProjects < ActiveRecord::Migration[6.1]
  def change
    add_column :projects, :languages, :json, default: []  end
end
