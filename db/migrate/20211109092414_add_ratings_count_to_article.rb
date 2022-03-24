class AddRatingsCountToArticle < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :ratings_count, :integer
  end
end
