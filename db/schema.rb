# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_11_18_115816) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "postgis"

  create_table "observations", force: :cascade do |t|
    t.string "unique_id"
    t.string "sname"
    t.string "cname"
    t.string "loc_text"
    t.datetime "obs_dttm"
    t.integer "obs_count", default: 1
    t.text "json"
    t.geography "location", limit: {:srid=>4326, :type=>"st_point", :geographic=>true}
    t.string "app_id"
    t.string "username"
    t.string "user_id"
    t.integer "quality_level"
    t.integer "location_accuracy"
    t.integer "identifications_count", default: 0
    t.integer "photos_count", default: 0
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["app_id"], name: "index_observations_on_app_id"
    t.index ["location"], name: "index_observations_on_location", using: :gist
    t.index ["unique_id"], name: "index_observations_on_unique_id", unique: true
  end

  create_table "photos", force: :cascade do |t|
    t.string "image_thumb_url"
    t.string "image_large_url"
    t.string "license_code"
    t.string "attribution"
    t.string "license_name"
    t.string "license_url"
    t.text "json"
    t.bigint "observation_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["observation_id"], name: "index_photos_on_observation_id"
  end

  create_table "regions", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.datetime "subscription_ends_at"
    t.string "header_image_url"
    t.string "logo_image_url"
    t.string "region_url"
    t.datetime "last_updated_at"
    t.integer "refresh_interval_mins", default: 60
    t.geography "polygon", limit: {:srid=>4326, :type=>"st_polygon", :geographic=>true}
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name"], name: "index_regions_on_name"
    t.index ["polygon"], name: "index_regions_on_polygon", using: :gist
  end

  add_foreign_key "photos", "observations"
end
