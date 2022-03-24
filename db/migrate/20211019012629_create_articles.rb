class CreateArticles < ActiveRecord::Migration[6.1]
  def change
    create_table :articles do |t|
      t.string :title
      t.text :description
      t.integer :category_id
      t.integer :author_id
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
