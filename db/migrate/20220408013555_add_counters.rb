class AddCounters < ActiveRecord::Migration[6.1]
  def change
    add_column :contests, :sightings_count, :integer, default: 0
    add_column :contests, :identifications_count, :integer, default: 0
    add_column :contests, :species_count, :integer, default: 0
    add_column :contests, :participants_count, :integer, default: 0 
    add_column :regions, :sightings_count, :integer, default: 0
    add_column :regions, :identifications_count, :integer, default: 0
    add_column :regions, :species_count, :integer, default: 0
    add_column :regions, :participants_count, :integer, default: 0 
    add_column :participations, :sightings_count, :integer, default: 0
    add_column :participations, :identifications_count, :integer, default: 0
    add_column :participations, :species_count, :integer, default: 0
    add_column :participations, :participants_count, :integer, default: 0 
  end
end
