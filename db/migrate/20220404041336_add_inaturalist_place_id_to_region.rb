class AddInaturalistPlaceIdToRegion < ActiveRecord::Migration[6.1]
  def change
    add_column :regions, :inaturalist_place_id, :integer
  end
end
