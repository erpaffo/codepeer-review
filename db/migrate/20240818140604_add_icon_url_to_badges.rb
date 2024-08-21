class AddIconUrlToBadges < ActiveRecord::Migration[6.1]
  def change
    add_column :badges, :icon_url, :string
  end
end
