class AddOrderToIngredient < ActiveRecord::Migration[6.1]
  def change
    add_column :ingredients, :order, :integer
  end
end
