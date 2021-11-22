class CreateDownloadableRegions < ActiveRecord::Migration[6.1]
    def change
        create_table :downloadable_regions do |t|
            t.string    :type, default: 'circle'
            t.string    :app_id
            t.float     :lat
            t.float     :lng
            t.float     :radius
            t.datetime  :start_at
            t.datetime  :end_at

            t.references :region, null: false, foreign_key: true

            t.timestamps
            t.datetime  :deleted_at
        end
    end
end
