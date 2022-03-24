class AddDefaultToUser < ActiveRecord::Migration[6.1]
  def change
    change_column :users, :articles_count, :integer, default: 0
  end
end
