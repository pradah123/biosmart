class AddTitleToStep < ActiveRecord::Migration[6.1]
  def change
    add_column :steps, :title, :string
    remove_column :steps, :description, :string
    remove_column :steps, :instruction, :string
    add_column :steps, :instruction, :text
  end
end
