class AddRadiusKmToSubregion < ActiveRecord::Migration[6.1]
  def change
    add_column :subregions, :radius_km, :float
  end
end
