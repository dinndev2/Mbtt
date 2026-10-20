require "csv"

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Two parts: reference data that every environment needs, then one worked
# example route that touches every table. The real Masbate network lives in
# data/gtfs/, which has no importer yet.

# ---------------------------------------------------------------------------
# Reference data
# ---------------------------------------------------------------------------

# Vihicle: the modes available on the island. route_type is the GTFS code these
# modes travel under (3 = road vehicle, 4 = ferry).
[
  { name: "Private",     slug: "private",     route_type: :road },
  { name: "Motorcycle",  slug: "motorcycle",  route_type: :road, description: "Habal-habal." },
  { name: "Tricycle",    slug: "tricycle",    route_type: :road },
  { name: "Van",         slug: "van",         route_type: :road },
  { name: "Bus",         slug: "bus",         route_type: :road },
  { name: "Mini Jeep",   slug: "mini-jeep",   route_type: :road },
  { name: "Ferry",       slug: "ferry",       route_type: :ferry },
  { name: "Boat",        slug: "boat",        route_type: :ferry, description: "Hired outrigger banca for island hopping." }
].each do |attributes|
  Vihicle.find_or_create_by!(slug: attributes[:slug]) do |vihicle|
    vihicle.assign_attributes(attributes)
  end
end

# Category: how places are grouped for browsing.
[
  { name: "Nature", slug: "nature" },
  { name: "City",   slug: "city" },
  { name: "Sea",    slug: "sea" }
].each do |attributes|
  Category.find_or_create_by!(slug: attributes[:slug]) do |category|
    category.name = attributes[:name]
  end
end

DATA = Rails.root.parent.join("data")

def csv_rows(path)
  path.exist? ? CSV.read(path, headers: true) : (Rails.logger.warn("missing #{path}"); [])
end

# Stops, from the GTFS feed. These are the network's nouns, so they load before
# anything that points at one -- the sample trip below included. Coordinates are
# mostly municipality centroids; mbtt_coord_precision records which, so the app
# can flag an approximate pin.
#
# GTFS location_type 0 is a platform you board at, 1 a station that contains
# them; the feed has no stations yet, but reading the column means the day one
# appears the seed does not quietly flatten it.
GTFS_LOCATION_TYPES = { "1" => :station }.freeze
GTFS_WHEELCHAIR     = { "1" => :accessible, "2" => :not_accessible }.freeze

csv_rows(DATA.join("gtfs", "stops.txt")).each do |row|
  stop = Stop.find_or_initialize_by(gtfs_id: row["stop_id"])
  stop.assign_attributes(
    name:                row["stop_name"],
    code:                row["stop_code"].presence,
    description:         row["stop_desc"].presence,
    latitude:            row["stop_lat"].presence,
    longitude:           row["stop_lon"].presence,
    zone_id:             row["zone_id"].presence,
    # Which island the stop is on, from the feed's mbtt_island extension. This
    # is what lets IslandConnection notice that a traveller is somewhere other
    # than where an access chain silently assumes they are standing.
    island:              row["mbtt_island"].presence,
    location_type:       GTFS_LOCATION_TYPES.fetch(row["location_type"], :boarding),
    wheelchair_boarding: GTFS_WHEELCHAIR.fetch(row["wheelchair_boarding"], :unknown)
  )
  stop.save!
end

# Terminal detail, from data/stops.csv rather than the feed. GTFS has nowhere
# to record that Aroroy is not a RoRo port or that San Jacinto is daytime
# navigation only, and both change whether a crossing is possible. Thirteen
# stops carry nothing but a role; those columns stay null on purpose.
csv_rows(DATA.join("stops.csv")).each do |row|
  stop = Stop.find_by(gtfs_id: row["stop_id"])
  next Rails.logger.warn("stops.csv references unknown stop #{row["stop_id"]}") unless stop

  stop.update!(
    role:              row["role"].presence,
    port_authority:    row["port_authority"].presence,
    navigation:        row["navigation"].presence,
    serves:            row["serves"].presence,
    operators:         row["operators"].presence,
    facilities:        row["facilities"].presence,
    ticketing:         row["ticketing"].presence,
    arrive_before_min: row["arrive_before_min"].presence,
    notes:             row["notes"].presence,
    detail_confidence: row["confidence"].presence,
    detail_as_of:      row["valid_as_of"].presence,
    detail_source:     row["source_url"].presence
  )
end

# ---------------------------------------------------------------------------
# Sample network: Masbate City to Mobo by mini jeep
# ---------------------------------------------------------------------------
#
# One route, end to end, so every table has something in it to develop against.
# Coordinates are approximate and the times are illustrative -- this is shaped
# like real data, but it is not surveyed data. Everything below matches on the
# same natural keys an importer would use, so re-running the seeds updates
# nothing and duplicates nothing.

agency = Agency.find_or_create_by!(gtfs_id: "AG_MBTT") do |a|
  a.name  = "Masbate City Transport Operators"
  a.url   = "https://example.org/mbtt"
  a.phone = "+63 56 000 0000"
end

# Both ends of the trip are real stops from data/gtfs/stops.txt, loaded above --
# the route is the illustration here, not the geography. Fail loudly if the feed
# stopped carrying them rather than seeding a lookalike under a new id.
terminal = Stop.find_by!(gtfs_id: "S_MASBATE_TERMINAL")
mobo     = Stop.find_by!(gtfs_id: "S_MOBO_POB")

route = Route.find_or_create_by!(gtfs_id: "R_JEEP_MASBATE_MOBO") do |r|
  r.agency      = agency
  r.vihicle     = Vihicle.find_by!(slug: "mini-jeep")
  r.long_name   = "Masbate City – Mobo"
  r.description = "Loads at the terminal until full. No fixed departures."
  r.route_type  = :road
  r.color       = "0F7B4A"
  r.text_color  = "FFFFFF"
end

service = Service.find_or_create_by!(gtfs_id: "DAILY") do |s|
  Service::DAYS.each { |day| s.public_send("#{day}=", true) }
  s.start_date = Date.new(2026, 9, 1)
  s.end_date   = Date.new(2027, 8, 31)
end

# All Souls' Day: the jeeps go to the cemetery route instead.
ServiceException.find_or_create_by!(service: service, date: Date.new(2026, 11, 2)) do |e|
  e.exception_type = :removed
end

trip = Trip.find_or_create_by!(gtfs_id: "R_JEEP_MASBATE_MOBO_DAILY_01") do |t|
  t.route     = route
  t.service   = service
  t.headsign  = "Mobo"
  t.direction = :outbound
end

# Two stops is the minimum a trip can have. timepoint is true only where the
# time is actually dependable -- here, the terminal's first run of the day.
[
  { stop: terminal, stop_sequence: 10, time: "06:00:00", timepoint: true,  km: 0.0 },
  { stop: mobo,     stop_sequence: 20, time: "06:25:00", timepoint: false, km: 9.4 }
].each do |attributes|
  stop_time = StopTime.find_or_initialize_by(trip: trip, stop_sequence: attributes[:stop_sequence])
  stop_time.assign_attributes(
    stop:                attributes[:stop],
    arrival_time:        attributes[:time],
    departure_time:      attributes[:time],
    timepoint:           attributes[:timepoint],
    shape_dist_traveled: attributes[:km]
  )
  stop_time.save!
end

# The jeep leaves when full, so the schedule is a wait, not a departure list.
# Mornings are busy; the rest of the day is not.
[
  { start_time: "05:00:00", end_time: "08:00:00", headway_secs: 900 },
  { start_time: "08:00:00", end_time: "18:00:00", headway_secs: 1800 }
].each do |attributes|
  Frequency.find_or_create_by!(trip: trip, start_time: attributes[:start_time]) do |f|
    f.end_time     = attributes[:end_time]
    f.headway_secs = attributes[:headway_secs]
    f.exact_times  = false
  end
end

fare = Fare.find_or_create_by!(gtfs_id: "F_JEEP_MASBATE_MOBO") do |f|
  f.agency         = agency
  f.price          = 25.00
  f.payment_method = :on_board
  f.transfers      = 0
end

FareRule.find_or_create_by!(fare: fare, route: route)

# ---------------------------------------------------------------------------
# Researched data, imported from data/
# ---------------------------------------------------------------------------
#
# Everything below is desk research -- ferry operator listings, LGU rates and
# travel blogs -- not survey. The CSVs under data/ are the source of truth:
# edit them and re-run, don't add rows here. Every import matches on the
# natural key so re-running upserts instead of duplicating.

MODE_TO_VIHICLE_SLUG = {
  "ferry" => "ferry", "boat" => "boat", "motorcycle" => "motorcycle",
  "jeep" => "mini-jeep", "van" => "van", "bus" => "bus", "tricycle" => "tricycle"
}.freeze

# Fare legs -- the priceable hops. See FareLeg for what basis/fare_kind mean.
csv_rows(DATA.join("fare_legs.csv")).each do |row|
  leg = FareLeg.find_or_initialize_by(external_id: row["leg_id"])
  leg.assign_attributes(
    from_stop:      Stop.find_by(gtfs_id: row["from_stop_id"]),
    to_stop:        Stop.find_by(gtfs_id: row["to_stop_id"]),
    vihicle:        Vihicle.find_by(slug: MODE_TO_VIHICLE_SLUG[row["mode"]]),
    amount_min_php: row["amount_min_php"].presence,
    amount_max_php: row["amount_max_php"].presence,
    basis:          row["basis"],
    covers_pax:     row["covers_pax"].presence || 1,
    fare_kind:      row["fare_kind"],
    duration_min:   row["duration_min"].presence,
    confidence:     row["confidence"],
    valid_as_of:    row["valid_as_of"].presence,
    source_url:     row["source_url"].presence,
    notes:          row["notes"].presence,
    # The timetable, taken from the research CSV rather than from the GTFS
    # feed on purpose: README's verify list has the feed contradicted in both
    # directions on R_RORO_MSB_PILAR and running three hours late on
    # R_PUMP_MSB_LAGUNDI. `departures_back` in particular is the return
    # direction the feed does not carry at all on the main gateway route.
    schedule_kind:   row["schedule_kind"].presence || "unknown",
    departures_out:  row["departures_out"].presence,
    departures_back: row["departures_back"].presence,
    service_start:   row["service_start"].presence,
    service_end:     row["service_end"].presence,
    headway_min:     row["headway_min"].presence,
    service_days:    row["service_days"].presence,
    # How far to trust the timetable above. Lives on the leg, not the route:
    # fare_legs.csv is the corrected source and routes.txt still carries the
    # figures it corrected.
    schedule_confidence: row["schedule_confidence"].presence || "unknown",
    schedule_as_of:      row["schedule_as_of"].presence,
    schedule_source:     row["schedule_source"].presence,
    schedule_note:       row["schedule_note"].presence
  )
  leg.save!
end

# Last trips, from data/last_trips.csv. The figure that decides whether a place
# is a day trip, and the one a timetable cannot be trusted to imply -- see the
# CreateLastTrips migration. Four rows today; the rest of the network either
# derives one from a real timetable or honestly reports that nobody knows.
csv_rows(DATA.join("last_trips.csv")).each do |row|
  leg  = FareLeg.find_by(external_id: row["leg_id"])
  stop = Stop.find_by(gtfs_id: row["board_stop_id"])
  unless leg && stop
    Rails.logger.warn("last_trips.csv row references unknown leg or stop: #{row["leg_id"]} / #{row["board_stop_id"]}")
    next
  end

  # Not `trip` -- the sample network below binds that name to a Trip record.
  last_trip = LastTrip.find_or_initialize_by(fare_leg: leg, board_stop: stop)
  last_trip.assign_attributes(
    last_departure: row["last_departure"],
    overnight:      row["overnight"].to_s == "1",
    confidence:     row["confidence"].presence || "unknown",
    valid_as_of:    row["valid_as_of"].presence,
    source_url:     row["source_url"].presence,
    notes:          row["notes"].presence
  )
  last_trip.save!
end

# Operators, from the GTFS feed. Where a mode has no formal operator -- habal
# habal drivers, most tricycle lines -- the feed carries one umbrella agency
# for it, because every route needs one.
csv_rows(DATA.join("gtfs", "agency.txt")).each do |row|
  agency = Agency.find_or_initialize_by(gtfs_id: row["agency_id"])
  agency.assign_attributes(
    name:     row["agency_name"],
    url:      row["agency_url"],
    timezone: row["agency_timezone"].presence || "Asia/Manila",
    lang:     row["agency_lang"].presence,
    phone:    row["agency_phone"].presence,
    email:    row["agency_email"].presence
  )
  agency.save!
end

# Routes, with how far to trust their timetables. A fare already said how much
# to trust it; a departure time did not, and that was the bigger lie -- GTFS
# renders 10:00:00 identically whether it came from Montenegro or from a guess
# about how often a habal-habal turns up. See gtfs/README.md for the counts;
# nothing in this feed is `published`.
GTFS_ROUTE_TYPES = { "3" => :road, "4" => :ferry }.freeze

csv_rows(DATA.join("gtfs", "routes.txt")).each do |row|
  vihicle = Vihicle.find_by(name: row["mbtt_mode"])
  agency  = Agency.find_by(gtfs_id: row["agency_id"])
  next unless vihicle && agency

  route = Route.find_or_initialize_by(gtfs_id: row["route_id"])
  route.assign_attributes(
    agency:      agency,
    vihicle:     vihicle,
    short_name:  row["route_short_name"].presence,
    long_name:   row["route_long_name"].presence,
    description: row["route_desc"].presence,
    route_type:  GTFS_ROUTE_TYPES.fetch(row["route_type"], :road),
    color:       row["route_color"].presence,
    text_color:  row["route_text_color"].presence,
    # The priced hop this timetable belongs to, so a fare estimate's legs can
    # say whether their times are real.
    fare_leg:            FareLeg.find_by(external_id: row["mbtt_leg_id"]),
    schedule_confidence: row["mbtt_schedule_confidence"].presence || "unknown",
    schedule_as_of:      row["mbtt_schedule_as_of"].presence,
    schedule_source:     row["mbtt_schedule_source"].presence,
    schedule_note:       row["mbtt_schedule_note"].presence
  )
  route.save!
end

# Places.
csv_rows(DATA.join("places.csv")).each do |row|
  place = Place.find_or_initialize_by(external_id: row["place_id"])
  place.assign_attributes(
    name:             row["name"],
    municipality:     row["municipality"],
    island:           row["island"],
    latitude:         row["latitude"].presence,
    longitude:        row["longitude"].presence,
    coord_status:     row["coord_status"],
    description:      row["description"].presence,
    access_note:      row["notes"].presence,
    travel_time_note: row["est_travel_time"].presence,
    source:           row["source"],
    # How well known, measured as published coverage -- nothing here counts
    # visits, so nothing here may be rendered as "most visited".
    prominence_rank:  row["prominence_rank"].presence,
    prominence_tier:  row["prominence_tier"].presence,
    source_count:     row["source_count"].presence,
    prominence_basis: row["prominence_basis"].presence,
    prominence_as_of: row["prominence_as_of"].presence
  )
  place.save!

  category = Category.find_by(slug: row["category"])
  PlaceCategory.find_or_create_by!(place: place, category: category) if category

  row["modes"].to_s.split(";").each do |mode|
    vihicle = Vihicle.find_by(slug: MODE_TO_VIHICLE_SLUG[mode.strip])
    PlaceVihicle.find_or_create_by!(place: place, vihicle: vihicle) if vihicle
  end
end

# Access chains. Option A and B are alternative routes in, not consecutive steps.
csv_rows(DATA.join("place_access.csv")).each do |row|
  place = Place.find_by(external_id: row["place_id"])
  leg   = FareLeg.find_by(external_id: row["leg_id"])
  next unless place && leg

  access = PlaceAccessLeg.find_or_initialize_by(
    place: place, option: row["option"], seq: row["seq"]
  )
  access.assign_attributes(fare_leg: leg, notes: row["notes"].presence)
  access.save!
end

# Entrance, environmental and docking fees.
csv_rows(DATA.join("place_fees.csv")).each do |row|
  place = Place.find_by(external_id: row["place_id"])
  next unless place

  fee = PlaceFee.find_or_initialize_by(external_id: row["fee_id"])
  fee.assign_attributes(
    place:          place,
    label:          row["label"],
    amount_min_php: row["amount_min_php"].presence,
    amount_max_php: row["amount_max_php"].presence,
    basis:          row["basis"],
    covers_pax:     row["covers_pax"].presence || 1,
    required:       row["required"] == "1",
    confidence:     row["confidence"],
    valid_as_of:    row["valid_as_of"].presence,
    source_url:     row["source_url"].presence,
    notes:          row["notes"].presence
  )
  fee.save!
end

# Images bundled under frontend/public. Commons CC BY-SA plus an open-web set
# marked `unverified`; both need their attribution to reach the UI -- see
# Image#credit and data/ATTRIBUTION.md.
#
# Places and stops share the images table but keep a CSV each, so either can
# be corrected by hand without scrolling past the other.
seed_image = lambda do |owner, row|
  image = Image.find_or_initialize_by(imageable: owner, seq: row["seq"])
  image.assign_attributes(
    local_path:  row["local_path"],
    license:     row["license"],
    attribution: row["attribution"].presence,
    source_page: row["source_page"].presence,
    bytes:       row["bytes"].presence,
    caption:     row["caption"].presence
  )
  image.save!
end

csv_rows(DATA.join("place_images.csv")).each do |row|
  place = Place.find_by(external_id: row["place_id"])
  seed_image.call(place, row) if place
end

csv_rows(DATA.join("stop_images.csv")).each do |row|
  stop = Stop.find_by(gtfs_id: row["stop_id"])
  seed_image.call(stop, row) if stop
end

# Operational notes -- the things a local would tell you that no fare table or
# timetable can hold. Everything here is a claim about how things *usually*
# are, never about right now: "the last pumpboat goes about 13:00" survives
# offline, "today's 10:30 crossing still has space" cannot, and so has no row.
csv_rows(DATA.join("advisories.csv")).each do |row|
  advisory = Advisory.find_or_initialize_by(external_id: row["advisory_id"])
  advisory.assign_attributes(
    scope:       row["scope"],
    scope_ref:   row["scope_ref"].presence,
    kind:        row["kind"],
    severity:    row["severity"],
    headline:    row["headline"],
    detail:      row["detail"].presence,
    season_from: row["season_from"].presence,
    season_to:   row["season_to"].presence,
    confidence:  row["confidence"],
    valid_as_of: row["valid_as_of"].presence,
    source_url:  row["source_url"].presence
  )
  advisory.save!
end

# A note naming a place or route that was never imported is a data gap, not an
# error -- say so loudly rather than dropping the row silently.
Advisory.where(scope: %w[place route leg]).find_each do |advisory|
  Rails.logger.warn("advisory #{advisory.external_id} points at missing #{advisory.scope} #{advisory.scope_ref}") if advisory.subject.nil?
end

# The illustrative sample places that used to sit here are gone -- P_BUNTOD and
# the Mobo market are covered by the researched data above.
Place.where(coord_status: "illustrative").destroy_all

# Same for the stops this file used to invent. S_MOBO_POBLACION was a second
# "Mobo Poblacion" alongside the feed's S_MOBO_POB; S_MASBATE_BAY_MOBO was a
# boarding bay no timetable ever used. The sample trip above points at the GTFS
# ids now, so both are unreferenced.
Stop.where(gtfs_id: %w[S_MOBO_POBLACION S_MASBATE_BAY_MOBO]).destroy_all

# Survey respondents, and one recorded ride.
local = User.find_or_create_by!(name: "Ana (local)") { |u| u.commuter_type = :local }
User.find_or_create_by!(name: "Migs (traveller)") { |u| u.commuter_type = :traveller }

History.find_or_create_by!(user: local, trip: trip)

# The island picker is the first choice in the app, so each line says what is
# there and roughly what it costs you in time -- that is what the choice turns
# on. Getting-there detail belongs on the place, not here.
[
  { name: "Masbate",
    description: "The mainland. Caves, beaches and lighthouses, all day trips from the city terminal." },
  { name: "Ticao",
    description: "Forty minutes by fastcraft. Manta rays, a waterfall into the sea, Bicol's last old mangroves." },
  { name: "Burias",
    description: "The island-hopping run: Sombrero, Animasola, Tinalisayan. Worth an overnight." }
].each do |attributes|
  Island.find_or_create_by!(name: attributes[:name]) do |island|
    island.description = attributes[:description]
  end
end