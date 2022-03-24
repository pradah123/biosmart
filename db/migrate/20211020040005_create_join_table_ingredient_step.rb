class CreateJoinTableIngredientStep < ActiveRecord::Migration[6.1]
  def change
    create_join_table :ingredients, :steps do |t|
      # t.index [:ingredient_id, :step_id]
      # t.index [:step_id, :ingredient_id]
    end
  end
end
