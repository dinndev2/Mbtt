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

ActiveRecord::Schema[8.0].define(version: 2026_08_17_091001) do
  create_table "agencies", force: :cascade do |t|
    t.string "gtfs_id", null: false
    t.string "name", null: false
    t.string "url"
    t.string "timezone", default: "Asia/Manila", null: false
    t.string "lang", default: "en"
    t.string "phone"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gtfs_id"], name: "index_agencies_on_gtfs_id", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.text "description"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "fare_rules", force: :cascade do |t|
    t.integer "fare_id", null: false
    t.integer "route_id"
    t.string "origin_zone"
    t.string "destination_zone"
    t.string "contains_zone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fare_id"], name: "index_fare_rules_on_fare_id"
    t.index ["route_id"], name: "index_fare_rules_on_route_id"
  end

  create_table "fares", force: :cascade do |t|
    t.string "gtfs_id", null: false
    t.integer "agency_id"
    t.decimal "price", precision: 8, scale: 2, null: false
    t.string "currency", default: "PHP", null: false
    t.integer "payment_method", default: 0, null: false
    t.integer "transfers", default: 0
    t.integer "transfer_duration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "stop_id"
    t.index ["agency_id"], name: "index_fares_on_agency_id"
    t.index ["gtfs_id"], name: "index_fares_on_gtfs_id", unique: true
    t.index ["stop_id"], name: "index_fares_on_stop_id"
  end

  create_table "frequencies", force: :cascade do |t|
    t.integer "trip_id", null: false
    t.time "start_time", null: false
    t.time "end_time", null: false
    t.integer "headway_secs", null: false
    t.boolean "exact_times", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["trip_id"], name: "index_frequencies_on_trip_id"
  end

  create_table "histories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.integer "trip_id"
    t.index ["trip_id"], name: "index_histories_on_trip_id"
    t.index ["user_id"], name: "index_histories_on_user_id"
  end

  create_table "place_categories", force: :cascade do |t|
    t.integer "place_id", null: false
    t.integer "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_place_categories_on_category_id"
    t.index ["place_id", "category_id"], name: "index_place_categories_on_place_id_and_category_id", unique: true
    t.index ["place_id"], name: "index_place_categories_on_place_id"
  end

  create_table "places", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.decimal "latitude", precision: 9, scale: 6
    t.decimal "longitude", precision: 9, scale: 6
    t.string "image_url"
    t.integer "stop_id"
    t.index ["stop_id"], name: "index_places_on_stop_id"
  end

  create_table "routes", force: :cascade do |t|
    t.string "gtfs_id", null: false
    t.integer "agency_id", null: false
    t.integer "vihicle_id", null: false
    t.string "short_name"
    t.string "long_name"
    t.text "description"
    t.integer "route_type", default: 3, null: false
    t.string "color"
    t.string "text_color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["agency_id"], name: "index_routes_on_agency_id"
    t.index ["gtfs_id"], name: "index_routes_on_gtfs_id", unique: true
    t.index ["vihicle_id"], name: "index_routes_on_vihicle_id"
  end

  create_table "service_exceptions", force: :cascade do |t|
    t.integer "service_id", null: false
    t.date "date", null: false
    t.integer "exception_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["service_id", "date"], name: "index_service_exceptions_on_service_id_and_date", unique: true
    t.index ["service_id"], name: "index_service_exceptions_on_service_id"
  end

  create_table "services", force: :cascade do |t|
    t.string "gtfs_id", null: false
    t.boolean "monday", default: false, null: false
    t.boolean "tuesday", default: false, null: false
    t.boolean "wednesday", default: false, null: false
    t.boolean "thursday", default: false, null: false
    t.boolean "friday", default: false, null: false
    t.boolean "saturday", default: false, null: false
    t.boolean "sunday", default: false, null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gtfs_id"], name: "index_services_on_gtfs_id", unique: true
  end

  create_table "stop_times", force: :cascade do |t|
    t.integer "trip_id", null: false
    t.integer "stop_id", null: false
    t.integer "stop_sequence", null: false
    t.time "arrival_time"
    t.time "departure_time"
    t.integer "pickup_type", default: 0, null: false
    t.integer "drop_off_type", default: 0, null: false
    t.boolean "timepoint", default: false, null: false
    t.decimal "shape_dist_traveled", precision: 8, scale: 3
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["stop_id"], name: "index_stop_times_on_stop_id"
    t.index ["trip_id", "stop_sequence"], name: "index_stop_times_on_trip_id_and_stop_sequence", unique: true
    t.index ["trip_id"], name: "index_stop_times_on_trip_id"
  end

  create_table "stops", force: :cascade do |t|
    t.string "gtfs_id", null: false
    t.string "code"
    t.string "name", null: false
    t.text "description"
    t.decimal "latitude", precision: 9, scale: 6
    t.decimal "longitude", precision: 9, scale: 6
    t.string "zone_id"
    t.integer "location_type", default: 0, null: false
    t.integer "parent_stop_id"
    t.integer "wheelchair_boarding", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gtfs_id"], name: "index_stops_on_gtfs_id", unique: true
    t.index ["parent_stop_id"], name: "index_stops_on_parent_stop_id"
    t.index ["zone_id"], name: "index_stops_on_zone_id"
  end

  create_table "trips", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "gtfs_id"
    t.integer "route_id"
    t.integer "service_id"
    t.string "headsign"
    t.integer "direction", default: 0, null: false
    t.index ["gtfs_id"], name: "index_trips_on_gtfs_id", unique: true
    t.index ["route_id"], name: "index_trips_on_route_id"
    t.index ["service_id"], name: "index_trips_on_service_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "commuter_type", default: 0
    t.string "name"
  end

  create_table "vihicles", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.integer "route_type", default: 3, null: false
    t.index ["slug"], name: "index_vihicles_on_slug", unique: true
  end

  add_foreign_key "fare_rules", "fares"
  add_foreign_key "fare_rules", "routes"
  add_foreign_key "fares", "agencies"
  add_foreign_key "fares", "stops"
  add_foreign_key "frequencies", "trips"
  add_foreign_key "histories", "trips"
  add_foreign_key "place_categories", "categories"
  add_foreign_key "place_categories", "places"
  add_foreign_key "places", "stops"
  add_foreign_key "routes", "agencies"
  add_foreign_key "routes", "vihicles"
  add_foreign_key "service_exceptions", "services"
  add_foreign_key "stop_times", "stops"
  add_foreign_key "stop_times", "trips"
  add_foreign_key "stops", "stops", column: "parent_stop_id"
  add_foreign_key "trips", "routes"
  add_foreign_key "trips", "services"
end
