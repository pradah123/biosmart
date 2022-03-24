class AddSearchTextToArticle < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :search_text, :text
  end
end
