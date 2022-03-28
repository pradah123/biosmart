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

ActiveRecord::Schema.define(version: 2022_01_22_074937) do

  #enable_extension "plpgsql"
  #enable_extension "postgis"

  create_table "users", force: :cascade do |t|
    t.string "organization_name"
    t.string "email"
    t.integer "role", default: 0
    t.integer "status", default: 0

    t.string "login_code"
    t.datetime "login_code_expires_at"
    t.string "jwt_token"
    t.string "password_digest"
    t.integer "login_attempts", default: 0
    t.integer "login_attempts_max", default: 5   
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "regions", force: :cascade do |t|
    t.integer "user_id"
    t.string "name"
    t.string "description"
    t.text "raw_polygon_json"
    t.string "region_url"
    t.integer "population"
    t.text "header_image"
    t.text "logo_image"
    t.string "header_image_url"
    t.string "logo_image_url"
    t.integer "status", default: 0
    #t.geography "multi_polygon", limit: { srid: 4326, type: "multi_polygon", geographic: true }
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "observations", force: :cascade do |t|
    t.float "lat"
    t.float "lng"
    t.integer "data_source_id"
    t.datetime "observed_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "observations_regions", force: :cascade do |t|
    t.integer "region_id"
    t.integer "observation_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end  




  create_table "contests", force: :cascade do |t|
    t.integer "user_id"
    t.string "title"
    t.string "description"
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.integer "status", default: 0
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "participations", force: :cascade do |t|
    t.integer "region_id"
    t.integer "contest_id"
    t.integer "status", default: 0
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "data_sources", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "data_sources_participations", force: :cascade do |t|
    t.integer "participation_id"
    t.integer "data_source_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "observations_participations", force: :cascade do |t|
    t.integer "observation_id"
    t.integer "participation_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end  

  create_table "contests_observations", force: :cascade do |t|
    t.integer "contest_id"
    t.integer "observation_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end





=begin
  create_table "downloadable_regions", force: :cascade do |t|
    t.string "app_id"
    t.jsonb "params", default: "{}", null: false
    t.integer "region_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "deleted_at"
  end

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
    t.datetime "deleted_at"

    t.string "clean_sname"
    t.jsonb "more", default: "{}"
    t.index "((more -> 'lat'::text))", name: "index_observations_on_more_lat"
    t.index "((more -> 'lng'::text))", name: "index_observations_on_more_lng"
    t.index "((more -> 'locId'::text))", name: "index_observations_on_more_locId"
    t.index "((more -> 'obsDt'::text))", name: "index_observations_on_more_obsDt"
    t.index "((more -> 'obsTime'::text))", name: "index_observations_on_more_obsTime"
    t.index "((more -> 'subId'::text))", name: "index_observations_on_more_subId"
    t.index ["app_id"], name: "index_observations_on_app_id"
    t.index ["clean_sname"], name: "index_observations_on_clean_sname"
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
    t.datetime "deleted_at"
    t.bigint "observation_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "unique_id"
    t.index ["observation_id"], name: "index_photos_on_observation_id"
    t.index ["unique_id"], name: "index_photos_on_unique_id", unique: true
  end
=end

end
