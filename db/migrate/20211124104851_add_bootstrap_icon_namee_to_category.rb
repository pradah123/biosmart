class AddBootstrapIconNameeToCategory < ActiveRecord::Migration[6.1]
  def change
    remove_column :categories, :boostrap_icon_name, :string
    add_column :categories, :bootstrap_icon_name, :string
  end
end
