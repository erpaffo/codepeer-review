class AddCriteriaToBadges < ActiveRecord::Migration[6.1]
  def change
    unless column_exists?(:badges, :criteria)
      add_column :badges, :criteria, :string
    end
  end
end
