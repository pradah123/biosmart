class AddUserIdToView < ActiveRecord::Migration[6.1]
  def change
    add_column :views, :user_id, :integer
  end
end
