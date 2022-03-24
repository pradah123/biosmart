class AddInstructionToStep < ActiveRecord::Migration[6.1]
  def change
    add_column :steps, :instruction, :string
    remove_column :steps, :name, :string
  end
end
