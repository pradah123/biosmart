class CreateIngredients < ActiveRecord::Migration[6.1]
  def change
    create_table :ingredients do |t|
      t.text :description
      t.integer :article_id

      t.timestamps
    end
  end
end
