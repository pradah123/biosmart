class AddHashcodeToArticle < ActiveRecord::Migration[6.1]
  def change
    add_column :articles, :hashcode, :string
  end
end
