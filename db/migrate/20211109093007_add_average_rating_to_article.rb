class AddAverageRatingToArticle < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :average_rating, :float, default: 0.0
  end
end
