class AddCommentsCountToArticle < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :comments_count, :integer
  end
end
