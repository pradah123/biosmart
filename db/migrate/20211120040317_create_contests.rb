class CreateContests < ActiveRecord::Migration[6.1]
    def change
        create_table :contests do |t|
            t.string    :title
            t.string    :description
            t.datetime  :begin_at
            t.datetime  :end_at
            t.text      :participating_regions, array: true, default: []
            t.references :observation, null: false, foreign_key: true
            t.datetime  :deleted_at

            t.timestamps
        end
    end
end
