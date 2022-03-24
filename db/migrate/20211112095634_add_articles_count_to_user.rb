class AddArticlesCountToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :articles_count, :integer
  end
end
