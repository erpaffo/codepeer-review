class ChangeCriteriaInBadges < ActiveRecord::Migration[6.1]
  def change
    change_column :badges, :criteria, :text
  end
end
