class AddCreatorNameToObservation < ActiveRecord::Migration[6.1]
  def change
    add_column :observations, :creator_name, :string
  end
end
