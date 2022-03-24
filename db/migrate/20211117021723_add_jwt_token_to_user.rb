class AddJwtTokenToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :jwt_token, :string
  end
end
