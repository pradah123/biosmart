class AddUrlTitleToArticle < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :url_title, :string
  end
end
