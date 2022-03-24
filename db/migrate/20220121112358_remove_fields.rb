class RemoveFields < ActiveRecord::Migration[6.1]
  def change
    remove_column :categories, :colour, :string
    remove_column :categories, :bootstrap_icon_name, :string
  end
end
