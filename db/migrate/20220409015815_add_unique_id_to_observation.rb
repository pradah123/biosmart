class AddUniqueIdToObservation < ActiveRecord::Migration[6.1]
  def change
    add_column :observations, :unique_id, :string
  end
end
