class CreateObservations < ActiveRecord::Migration[6.1]
    def change
        create_table :observations do |t|
            t.string    :unique_id, index: {unique: true}
            t.string    :sname
            t.string    :cname
            t.string    :loc_text
            t.datetime  :obs_dttm
            t.integer   :obs_count, default: 1
            t.text      :json
            t.st_point  :location, geographic: true
            t.string    :app_id, index: true
            t.string    :username
            t.string    :user_id
            t.integer   :quality_level
            t.integer   :location_accuracy
            t.integer   :identifications_count, default: 0
            t.integer   :photos_count, default: 0

            t.index     :location, using: :gist
            t.datetime  :deleted_at
            
            t.timestamps
        end
    end
end
