class AddHasArticlesToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :has_articles, :boolean, default: false
  end
end
