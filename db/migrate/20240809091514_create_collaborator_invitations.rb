class CreateCollaboratorInvitations < ActiveRecord::Migration[6.1]
  def change
    create_table :collaborator_invitations do |t|
      t.references :project, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :email, null: false
      t.string :token, null: false
      t.boolean :accepted, default: false

      t.timestamps
    end

    add_index :collaborator_invitations, :token, unique: true
  end
end
