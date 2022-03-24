class Defaults < ActiveRecord::Migration[6.1]
  def change
    change_column :users, :ratings_count, :integer, default: 0
    change_column :articles, :ratings_count, :integer, default: 0
    change_column :users, :comments_count, :integer, default: 0
    change_column :articles, :comments_count, :integer, default: 0
    change_column :articles, :views_count, :integer, default: 0
  end
end
