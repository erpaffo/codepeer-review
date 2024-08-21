class ChangeCriteriaToJsonInBadges < ActiveRecord::Migration[6.0]
  def change
    change_column :badges, :criteria, :jsonb, default: '{}'
  end
end
