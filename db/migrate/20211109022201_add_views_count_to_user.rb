class AddViewsCountToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :views_count, :integer, default: 0
  end
end
