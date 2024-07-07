class AddTwoFactorToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :phone_number, :string
    add_column :users, :otp_secret, :string
    add_column :users, :otp_enabled, :boolean, default: false
  end
end
