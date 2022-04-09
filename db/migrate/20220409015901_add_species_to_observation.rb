class AddSpeciesToObservation < ActiveRecord::Migration[6.1]
  def change
    add_column :observations, :species, :string
  end
end
