class AddDraftToSnippets < ActiveRecord::Migration[6.0]
  def change
    add_column :snippets, :draft, :boolean, default: false
  end
end
