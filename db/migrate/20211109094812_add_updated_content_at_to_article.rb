class AddUpdatedContentAtToArticle < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :updated_content_at, :datetime
  end
end
