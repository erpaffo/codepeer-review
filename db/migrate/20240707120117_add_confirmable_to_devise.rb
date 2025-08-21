class AddConfirmableToDevise < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string
    add_index :users, :confirmation_token, unique: true

    # Update existing users as confirmed (guard if model available)
    if ActiveRecord::Base.connection.table_exists?(:users)
      begin
        User.reset_column_information
        User.update_all confirmed_at: DateTime.now
      rescue NameError
        # In case User model is not loaded during migration bootstrap
        execute "UPDATE users SET confirmed_at = CURRENT_TIMESTAMP WHERE confirmed_at IS NULL"
      end
    end
  end
end
