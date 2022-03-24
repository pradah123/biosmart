class AddLoginCodeToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :login_code, :string
  end
end
