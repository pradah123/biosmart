class AddFieldsToObservation < ActiveRecord::Migration[6.1]
  def change
    add_column :observations, :scientific_name, :string
    add_column :observations, :common_name, :string
    add_column :observations, :accepted_name, :string
    add_column :observations, :identifications_count, :integer, default: 0
    add_column :observations, :external_link, :string
    remove_column :observations, :observation_link, :string   
    remove_column :observations, :species, :string
  end
end
