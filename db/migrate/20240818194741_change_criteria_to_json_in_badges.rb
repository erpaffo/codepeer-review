class ChangeCriteriaToJsonInBadges < ActiveRecord::Migration[6.0]
  def up
    # Aggiungi una nuova colonna temporanea di tipo jsonb
    add_column :badges, :criteria_temp, :jsonb, default: '{}'

    # Copia i dati dalla vecchia colonna alla nuova colonna
    execute <<-SQL.squish
      UPDATE badges
      SET criteria_temp = criteria::jsonb
    SQL

    # Rimuovi la vecchia colonna
    remove_column :badges, :criteria

    # Rinomina la colonna temporanea nella colonna originale
    rename_column :badges, :criteria_temp, :criteria
  end

  def down
    # Ripristina la colonna al tipo originale (se necessario)
    change_column :badges, :criteria, :text
  end
end
