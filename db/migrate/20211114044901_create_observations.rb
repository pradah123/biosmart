class CreateObservations < ActiveRecord::Migration[5.2]
    def change
        create_table :observations do |t|
            t.string    :unique_id, index: true
            t.string    :sname
            t.string    :cname
            t.string    :loc_text
            t.datetime  :obs_dttm
            t.integer   :obs_count, default: 1
            t.text      :json
            t.st_point  :location, geographic: true

            t.index     :location, using: :gist

            t.timestamps
        end
    end
end
