class AddColourToCategory < ActiveRecord::Migration[6.1]
  def change
    add_column :categories, :colour, :string
  end
end
