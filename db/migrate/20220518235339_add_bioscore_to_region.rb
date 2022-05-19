class AddBioscoreToRegion < ActiveRecord::Migration[7.0]
  def change
    add_column :regions, :bioscore, :float
  end
end
