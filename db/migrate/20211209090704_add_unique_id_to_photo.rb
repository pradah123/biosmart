class AddUniqueIdToPhoto < ActiveRecord::Migration[6.1]
    def change
        add_column  :photos, :unique_id, :string
        add_index   :photos, :unique_id, unique: true
    end
end
