class AddPermissionsToCollaborators < ActiveRecord::Migration[6.1]
  def change
    add_column :collaborators, :permissions, :string, default: "partial"  # Valori possibili: 'full', 'partial'
  end
end
