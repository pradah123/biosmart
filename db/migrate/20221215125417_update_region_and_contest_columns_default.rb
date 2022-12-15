class UpdateRegionAndContestColumnsDefault < ActiveRecord::Migration[7.0]
  def change
    change_column :regions, :fetch_neighboring_region_data, :boolean, default: true, null: false
    change_column :regions, :create_neighboring_region_subregions_for_ebird, :boolean, default: true, null: false
    change_column :contests, :fetch_neighboring_region_data, :boolean, default: true, null: false

    execute %Q(
      UPDATE regions
      SET fetch_neighboring_region_data = true, create_neighboring_region_subregions_for_ebird = true
    )
    execute %Q(
      UPDATE contests
      SET fetch_neighboring_region_data = true
    )
  end
end
