class AddRankingScoreToArticle < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :ranking_score, :float
  end
end
