class CreateSteps < ActiveRecord::Migration[6.1]
  def change
    create_table :steps do |t|
      t.string :name
      t.text :description
      t.integer :order
      t.integer :article_id

      t.timestamps
    end
  end
end
