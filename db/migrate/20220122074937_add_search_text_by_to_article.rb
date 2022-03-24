class AddSearchTextByToArticle < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :search_text_by, :text
  end
end
