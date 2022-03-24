class AddSearchTextUsesToArticle < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :search_text_uses, :text
  end
end
