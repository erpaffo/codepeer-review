class AddLanguageToSnippets < ActiveRecord::Migration[6.1]
  def change
    add_column :snippets, :language, :string
  end
end
