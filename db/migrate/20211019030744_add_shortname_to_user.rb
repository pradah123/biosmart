class AddShortnameToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :shortname, :string
  end
end
