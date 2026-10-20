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

ActiveRecord::Schema[8.0].define(version: 2026_10_02_100000) do
  create_table "advisories", force: :cascade do |t|
    t.string "external_id", null: false
    t.string "scope", null: false
    t.string "scope_ref"
    t.string "kind", null: false
    t.string "severity", default: "info", null: false
    t.string "headline", null: false
    t.text "detail"
    t.string "season_from"
    t.string "season_to"
    t.string "confidence", default: "unknown", null: false
    t.date "valid_as_of"
    t.string "source_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_advisories_on_external_id", unique: true
    t.index ["scope", "scope_ref"], name: "index_advisories_on_scope_and_scope_ref"
    t.index ["severity"], name: "index_advisories_on_severity"
  end

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

  create_table "fare_legs", force: :cascade do |t|
    t.string "external_id", null: false
    t.integer "from_stop_id"
    t.integer "to_stop_id"
    t.integer "vihicle_id"
    t.decimal "amount_min_php", precision: 10, scale: 2
    t.decimal "amount_max_php", precision: 10, scale: 2
    t.string "basis", null: false
    t.integer "covers_pax", default: 1, null: false
    t.string "fare_kind", null: false
    t.integer "duration_min"
    t.string "confidence", default: "unknown", null: false
    t.date "valid_as_of"
    t.string "source_url"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "schedule_kind", default: "unknown", null: false
    t.string "departures_out"
    t.string "departures_back"
    t.string "service_start"
    t.string "service_end"
    t.integer "headway_min"
    t.string "service_days"
    t.string "schedule_confidence", default: "unknown", null: false
    t.date "schedule_as_of"
    t.string "schedule_source"
    t.text "schedule_note"
    t.index ["external_id"], name: "index_fare_legs_on_external_id", unique: true
    t.index ["from_stop_id"], name: "index_fare_legs_on_from_stop_id"
    t.index ["to_stop_id"], name: "index_fare_legs_on_to_stop_id"
    t.index ["vihicle_id"], name: "index_fare_legs_on_vihicle_id"
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

  create_table "images", force: :cascade do |t|
    t.integer "imageable_id", null: false
    t.integer "seq", null: false
    t.string "local_path", null: false
    t.string "license", null: false
    t.string "attribution"
    t.string "source_page"
    t.integer "bytes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "imageable_type", null: false
    t.string "caption"
    t.index ["imageable_type", "imageable_id", "seq"], name: "index_images_on_imageable_type_and_imageable_id_and_seq", unique: true
  end

  create_table "islands", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "last_trips", force: :cascade do |t|
    t.integer "fare_leg_id", null: false
    t.integer "board_stop_id", null: false
    t.string "last_departure", null: false
    t.boolean "overnight", default: false, null: false
    t.string "confidence", default: "unknown", null: false
    t.date "valid_as_of"
    t.string "source_url"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["board_stop_id"], name: "index_last_trips_on_board_stop_id"
    t.index ["fare_leg_id", "board_stop_id"], name: "index_last_trips_on_fare_leg_id_and_board_stop_id", unique: true
    t.index ["fare_leg_id"], name: "index_last_trips_on_fare_leg_id"
  end

  create_table "place_access_legs", force: :cascade do |t|
    t.integer "place_id", null: false
    t.integer "fare_leg_id", null: false
    t.string "option", default: "A", null: false
    t.integer "seq", null: false
    t.string "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fare_leg_id"], name: "index_place_access_legs_on_fare_leg_id"
    t.index ["place_id", "option", "seq"], name: "index_place_access_legs_on_place_id_and_option_and_seq", unique: true
    t.index ["place_id"], name: "index_place_access_legs_on_place_id"
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

  create_table "place_fees", force: :cascade do |t|
    t.string "external_id", null: false
    t.integer "place_id", null: false
    t.string "label", null: false
    t.decimal "amount_min_php", precision: 10, scale: 2
    t.decimal "amount_max_php", precision: 10, scale: 2
    t.string "basis", null: false
    t.integer "covers_pax", default: 1, null: false
    t.boolean "required", default: true, null: false
    t.string "confidence", default: "unknown", null: false
    t.date "valid_as_of"
    t.string "source_url"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_place_fees_on_external_id", unique: true
    t.index ["place_id"], name: "index_place_fees_on_place_id"
  end

  create_table "place_vihicles", force: :cascade do |t|
    t.integer "place_id", null: false
    t.integer "vihicle_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["place_id", "vihicle_id"], name: "index_place_vihicles_on_place_id_and_vihicle_id", unique: true
    t.index ["place_id"], name: "index_place_vihicles_on_place_id"
    t.index ["vihicle_id"], name: "index_place_vihicles_on_vihicle_id"
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
    t.string "external_id"
    t.string "municipality"
    t.string "island"
    t.string "coord_status"
    t.string "source"
    t.decimal "entrance_fee_php", precision: 8, scale: 2
    t.string "fare_note"
    t.string "travel_time_note"
    t.text "access_note"
    t.integer "prominence_rank"
    t.string "prominence_tier"
    t.integer "source_count"
    t.string "prominence_basis"
    t.date "prominence_as_of"
    t.index ["external_id"], name: "index_places_on_external_id", unique: true
    t.index ["island"], name: "index_places_on_island"
    t.index ["municipality"], name: "index_places_on_municipality"
    t.index ["prominence_rank"], name: "index_places_on_prominence_rank"
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
    t.string "schedule_confidence", default: "unknown", null: false
    t.date "schedule_as_of"
    t.string "schedule_source"
    t.text "schedule_note"
    t.integer "fare_leg_id"
    t.index ["agency_id"], name: "index_routes_on_agency_id"
    t.index ["fare_leg_id"], name: "index_routes_on_fare_leg_id"
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
    t.string "island"
    t.string "role"
    t.string "port_authority"
    t.string "navigation"
    t.string "serves"
    t.string "operators"
    t.string "facilities"
    t.string "ticketing"
    t.integer "arrive_before_min"
    t.text "notes"
    t.string "detail_confidence"
    t.date "detail_as_of"
    t.string "detail_source"
    t.index ["gtfs_id"], name: "index_stops_on_gtfs_id", unique: true
    t.index ["island"], name: "index_stops_on_island"
    t.index ["parent_stop_id"], name: "index_stops_on_parent_stop_id"
    t.index ["role"], name: "index_stops_on_role"
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

  add_foreign_key "fare_legs", "stops", column: "from_stop_id"
  add_foreign_key "fare_legs", "stops", column: "to_stop_id"
  add_foreign_key "fare_legs", "vihicles"
  add_foreign_key "fare_rules", "fares"
  add_foreign_key "fare_rules", "routes"
  add_foreign_key "fares", "agencies"
  add_foreign_key "fares", "stops"
  add_foreign_key "frequencies", "trips"
  add_foreign_key "histories", "trips"
  add_foreign_key "last_trips", "fare_legs"
  add_foreign_key "last_trips", "stops", column: "board_stop_id"
  add_foreign_key "place_access_legs", "fare_legs"
  add_foreign_key "place_access_legs", "places"
  add_foreign_key "place_categories", "categories"
  add_foreign_key "place_categories", "places"
  add_foreign_key "place_fees", "places"
  add_foreign_key "place_vihicles", "places"
  add_foreign_key "place_vihicles", "vihicles"
  add_foreign_key "places", "stops"
  add_foreign_key "routes", "agencies"
  add_foreign_key "routes", "fare_legs"
  add_foreign_key "routes", "vihicles"
  add_foreign_key "service_exceptions", "services"
  add_foreign_key "stop_times", "stops"
  add_foreign_key "stop_times", "trips"
  add_foreign_key "stops", "stops", column: "parent_stop_id"
  add_foreign_key "trips", "routes"
  add_foreign_key "trips", "services"
end
