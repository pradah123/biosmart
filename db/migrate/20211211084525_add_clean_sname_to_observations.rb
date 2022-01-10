class AddCleanSnameToObservations < ActiveRecord::Migration[6.1]
    def change
        add_column  :observations, :clean_sname, :string
        add_index   :observations, :clean_sname
    end
end
