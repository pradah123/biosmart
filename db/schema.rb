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

ActiveRecord::Schema.define(version: 2022_04_29_012146) do

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.integer "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "api_request_logs", force: :cascade do |t|
    t.integer "nobservations"
    t.integer "data_source_id"
    t.integer "ncreates"
    t.integer "ncreates_failed"
    t.integer "nupdates"
    t.integer "nupdates_no_change"
    t.integer "nupdates_failed"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "job_id"
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
    t.integer "sightings_count", default: 0
    t.integer "identifications_count", default: 0
    t.integer "species_count", default: 0
    t.integer "participants_count", default: 0
    t.datetime "final_at"
    t.datetime "last_submission_accepted_at"
    t.datetime "utc_starts_at"
    t.datetime "utc_ends_at"
  end

  create_table "contests_observations", force: :cascade do |t|
    t.integer "contest_id"
    t.integer "observation_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "contests_participations", force: :cascade do |t|
    t.integer "contest_id"
    t.integer "participation_id"
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

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", precision: 6
    t.datetime "updated_at", precision: 6
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "observation_images", force: :cascade do |t|
    t.integer "observation_id"
    t.string "url"
    t.string "url_thumbnail"
    t.string "license_code"
    t.string "attribution"
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
    t.string "unique_id"
    t.string "image_link"
    t.string "scientific_name", default: "TBD"
    t.string "common_name"
    t.string "accepted_name"
    t.integer "identifications_count", default: 0
    t.string "external_link"
    t.string "creator_name"
    t.datetime "last_submission_accepted_at"
    t.string "creator_id"
    t.integer "observation_images_count", default: 0
  end

  create_table "observations_participations", force: :cascade do |t|
    t.integer "observation_id"
    t.integer "participation_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "observations_regions", force: :cascade do |t|
    t.integer "region_id"
    t.integer "observation_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "participations", force: :cascade do |t|
    t.integer "user_id"
    t.integer "region_id"
    t.integer "contest_id"
    t.integer "status", default: 0
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "sightings_count", default: 0
    t.integer "identifications_count", default: 0
    t.integer "species_count", default: 0
    t.integer "participants_count", default: 0
    t.datetime "starts_at"
    t.datetime "ends_at"
    t.datetime "last_submission_accepted_at"
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
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "inaturalist_place_id"
    t.integer "sightings_count", default: 0
    t.integer "identifications_count", default: 0
    t.integer "species_count", default: 0
    t.integer "participants_count", default: 0
    t.integer "timezone_offset_mins", default: 0
    t.integer "observation_dot_org_id"
  end

  create_table "subregions", force: :cascade do |t|
    t.string "params_json", default: "{}"
    t.integer "region_id"
    t.integer "data_source_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.float "lat"
    t.float "lng"
    t.float "radius_km"
    t.text "raw_polygon_json"
    t.float "max_radius_km", default: 50.0
    t.integer "parent_subregion_id"
    t.index ["data_source_id"], name: "index_subregions_on_data_source_id"
    t.index ["region_id"], name: "index_subregions_on_region_id"
  end

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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "subregions", "data_sources", on_delete: :cascade
  add_foreign_key "subregions", "regions", on_delete: :cascade
end
