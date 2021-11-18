class CreateRegions < ActiveRecord::Migration[6.1]
    def change
        create_table :regions do |t|
            t.string    :name, index: true
            t.string    :description
            t.datetime  :subscription_ends_at
            t.string    :header_image_url
            t.string    :logo_image_url
            t.string    :region_url
            t.datetime  :last_updated_at
            t.integer   :refresh_interval_mins, default: 60
            t.st_polygon :polygon, geographic: true
            
            t.index     :polygon, using: :gist
            
            t.timestamps
        end
    end
end
