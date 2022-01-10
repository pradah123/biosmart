class CreatePhotos < ActiveRecord::Migration[6.1]
    def change
        create_table :photos do |t|
            t.string :image_thumb_url
            t.string :image_large_url
            t.string :license_code
            t.string :attribution
            t.string :license_name
            t.string :license_url
            t.datetime  :deleted_at

            t.references :observation, null: false, foreign_key: true

            t.timestamps
        end
    end
end
