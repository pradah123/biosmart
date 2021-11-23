class CreateDownloadableRegions < ActiveRecord::Migration[6.1]
    def change
        create_table :downloadable_regions do |t|
            t.string    :app_id
            t.jsonb     :params, null: false, default: '{}'

            t.references :region, null: false, foreign_key: true

            t.timestamps
            
            t.datetime  :deleted_at
            
            t.index     :params, using: :gin
        end
    end
end
