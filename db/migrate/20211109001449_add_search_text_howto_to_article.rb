class AddSearchTextHowtoToArticle < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :search_text_howto, :text
  end
end
