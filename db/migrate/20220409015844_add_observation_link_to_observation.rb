class AddObservationLinkToObservation < ActiveRecord::Migration[6.1]
  def change
    add_column :observations, :observation_link, :string
  end
end
