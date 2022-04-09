class AddImageLinkToObservation < ActiveRecord::Migration[6.1]
  def change
    add_column :observations, :image_link, :string
  end
end
