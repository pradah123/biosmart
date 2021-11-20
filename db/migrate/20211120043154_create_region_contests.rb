class CreateRegionContests < ActiveRecord::Migration[6.1]
    def change
        create_table :region_contests do |t|
            t.datetime  :deleted_at

            t.references :region, null: false, foreign_key: true
            t.references :contest, null: false, foreign_key: true

            t.timestamps
        end
    end
end
