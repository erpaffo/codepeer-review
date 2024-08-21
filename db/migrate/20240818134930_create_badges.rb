# db/migrate/[TIMESTAMP]_create_badges.rb
class CreateBadges < ActiveRecord::Migration[6.1]
  def change
    create_table :badges do |t|
      t.string :name
      t.text :description
      t.string :icon
      t.json :criteria, default: {}

      t.timestamps
    end
  end
end
