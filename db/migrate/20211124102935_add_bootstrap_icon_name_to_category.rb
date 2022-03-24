class AddBootstrapIconNameToCategory < ActiveRecord::Migration[6.1]
  def change
    add_column :categories, :boostrap_icon_name, :string
  end
end
