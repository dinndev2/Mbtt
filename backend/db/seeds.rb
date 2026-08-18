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
  { name: "Ferry",       slug: "ferry",       route_type: :ferry }
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

# The city terminal is a station; the bay inside it is where you actually board.
terminal = Stop.find_or_create_by!(gtfs_id: "S_MASBATE_TERMINAL") do |s|
  s.name          = "Masbate City Integrated Terminal"
  s.description   = "Main terminal building"
  s.latitude      = 12.370500
  s.longitude     = 123.622800
  s.zone_id       = "Z_CITY"
  s.location_type = :station
end

city_bay = Stop.find_or_create_by!(gtfs_id: "S_MASBATE_BAY_MOBO") do |s|
  s.name          = "Mobo bay, Masbate terminal"
  s.description   = "Jeep loading bay on the market side"
  s.latitude      = 12.370200
  s.longitude     = 123.623100
  s.zone_id       = "Z_CITY"
  s.location_type = :boarding
  s.parent_stop   = terminal
end

mobo = Stop.find_or_create_by!(gtfs_id: "S_MOBO_POBLACION") do |s|
  s.name          = "Mobo Poblacion"
  s.description   = "Roadside stop across the municipal hall"
  s.latitude      = 12.322000
  s.longitude     = 123.616000
  s.zone_id       = "Z_MOBO"
  s.location_type = :boarding
end

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
  { stop: city_bay, stop_sequence: 10, time: "06:00:00", timepoint: true,  km: 0.0 },
  { stop: mobo,     stop_sequence: 20, time: "06:25:00", timepoint: false, km: 9.4 }
].each do |attributes|
  StopTime.find_or_create_by!(trip: trip, stop_sequence: attributes[:stop_sequence]) do |st|
    st.stop                = attributes[:stop]
    st.arrival_time        = attributes[:time]
    st.departure_time      = attributes[:time]
    st.timepoint           = attributes[:timepoint]
    st.shape_dist_traveled = attributes[:km]
  end
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

# A place is somewhere a visitor wants to go; stop is where they board for it.
[
  {
    name: "Buntod Reef Marine Sanctuary",
    description: "Sandbar and reef off the city, reached by boat from the terminal side.",
    latitude: 12.353000, longitude: 123.639000,
    stop: terminal,
    categories: %w[sea nature]
  },
  {
    name: "Mobo Public Market",
    description: "Morning market at the end of the jeep line.",
    latitude: 12.322500, longitude: 123.615500,
    stop: mobo,
    categories: %w[city]
  }
].each do |attributes|
  place = Place.find_or_create_by!(name: attributes[:name]) do |p|
    p.description = attributes[:description]
    p.latitude    = attributes[:latitude]
    p.longitude   = attributes[:longitude]
    p.stop        = attributes[:stop]
  end

  attributes[:categories].each do |slug|
    PlaceCategory.find_or_create_by!(place: place, category: Category.find_by!(slug: slug))
  end
end

# Survey respondents, and one recorded ride.
local = User.find_or_create_by!(name: "Ana (local)") { |u| u.commuter_type = :local }
User.find_or_create_by!(name: "Migs (traveller)") { |u| u.commuter_type = :traveller }

History.find_or_create_by!(user: local, trip: trip)
