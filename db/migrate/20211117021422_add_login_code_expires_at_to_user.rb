class AddLoginCodeExpiresAtToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :login_code_expires_at, :datetime
  end
end
