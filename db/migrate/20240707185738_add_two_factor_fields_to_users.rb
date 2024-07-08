class AddTwoFactorFieldsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :two_factor_method, :string
    add_column :users, :otp_secret, :string
  end
end
