class AddDefaultToRankingScore < ActiveRecord::Migration[6.1]
  def change
    change_column :articles, :ranking_score, :float, default: 0.0
  end
end
