require "test_helper"

class BundlesControllerTest < ActionDispatch::IntegrationTest
  def setup
    ferry = Vihicle.find_or_create_by!(slug: "ferry") { |v| v.name = "Ferry"; v.route_type = :ferry }
    boat  = Vihicle.find_or_create_by!(slug: "boat")  { |v| v.name = "Boat";  v.route_type = :ferry }

    city_pier   = stop("B_CITY_PIER",   "City Pier",   "Masbate", "Z_CITY")
    city_reef   = stop("B_CITY_REEF",   "City Reef",   "Masbate", "Z_CITY")
    island_pier = stop("B_ISLAND_PIER", "Island Pier", "Ticao",   "Z_TICAO")
    island_town = stop("B_ISLAND_TOWN", "Island Town", "Ticao",   "Z_TICAO")

    crossing = leg("B_CROSSING", city_pier, island_pier, 243, ferry,
                   departures_out: "10:00", departures_back: "07:00")
    place("B_REEF",  "Reef Sandbar", "Masbate", [ leg("B_REEF_HOP", city_pier, city_reef, 500, boat) ])
    place("B_FALLS", "Island Falls", "Ticao",   [ crossing, leg("B_ONWARD", island_pier, island_town, 300, boat) ])
  end

  # The bug this endpoint was rebuilt around: the island selector asks "leaving
  # from", and the controller used that answer to filter places *to* that
  # island, so a traveller on Ticao could never be shown a Masbate place at all.
  test "where the traveller is does not hide where they can go" do
    get api_v1_bundles_url, params: { from: "ticao" }
    assert_response :success

    names = places.map { |place| place["external_id"] }
    assert_includes names, "B_REEF",  "a Masbate place must still be offered to someone on Ticao"
    assert_includes names, "B_FALLS"
    assert_equal "ticao", body["meta"]["from_island"]
  end

  test "island still narrows the destinations when asked to" do
    get api_v1_bundles_url, params: { from: "ticao", island: "ticao" }
    assert_response :success

    assert_equal [ "Ticao" ], places.map { |place| place["island"] }.uniq
  end

  test "a place on another island carries the crossing to it" do
    get api_v1_bundles_url, params: { from: "ticao", pax: 2 }

    estimate = place_named("B_REEF")["fare_estimates"].first
    connection = estimate["connection"]

    assert_equal "Masbate", estimate["origin_island"]
    assert_equal "Ticao",   connection["from_island"]
    assert_equal "Masbate", connection["to_island"]
    assert connection["reachable"]

    crossing = connection["steps"].first["crossings"].first
    assert_equal "back",        crossing["direction"], "riding towards Masbate is the return direction"
    assert_equal "Island Pier", crossing["from"]
    assert_equal "City Pier",   crossing["to"]
    assert_equal [ "07:00" ],   crossing["departures"], "and must read the return timetable"
  end

  test "a place on the traveller's own island carries no crossing and no crossing fare" do
    get api_v1_bundles_url, params: { from: "ticao" }

    estimate = place_named("B_FALLS")["fare_estimates"].first

    assert_nil estimate["connection"], "nobody needs telling how to reach where they already are"
    assert_equal [ "B_ONWARD" ], estimate["legs"].map { |leg| leg["id"] }
    assert_equal 300.0, estimate["min_php"], "the ferry onto Ticao is not their fare to pay"
  end

  test "with no origin the bundle still answers, uncustomised" do
    get api_v1_bundles_url
    assert_response :success

    estimate = place_named("B_FALLS")["fare_estimates"].first
    assert_nil estimate["connection"]
    assert_equal [ "B_CROSSING", "B_ONWARD" ], estimate["legs"].map { |leg| leg["id"] }
  end

  # Places and stops share one images table. A stop's photos ride on the stop
  # directory only - the frontend looks every stop up there - and each one
  # carries its credit, which the licence requires, and what it shows.
  test "stop photos come with the stop directory, credited and captioned" do
    pier = Stop.find_by!(gtfs_id: "B_CITY_PIER")
    Image.create!(imageable: pier, seq: 1, local_path: "/images/stops/b_city_pier-1.jpg",
                  license: "CC BY-SA 4.0", attribution: "A. Photographer",
                  caption: "The pier from the water.")
    Image.create!(imageable: Place.find_by!(external_id: "B_REEF"), seq: 1,
                  local_path: "/images/places/b_reef-1.jpg", license: "CC BY-SA 4.0")

    get api_v1_bundles_url, params: { from: "masbate" }

    directory_pier = body["stops"].find { |stop| stop["gtfs_id"] == "B_CITY_PIER" }
    assert_equal [ "/images/stops/b_city_pier-1.jpg" ], directory_pier["images"].map { |image| image["url"] }
    assert_equal "A. Photographer / CC BY-SA 4.0", directory_pier["images"].first["credit"]
    assert_equal "The pier from the water.",      directory_pier["images"].first["caption"]

    assert_equal [ "/images/places/b_reef-1.jpg" ], place_named("B_REEF")["images"].map { |image| image["url"] },
                 "a place still gets only its own photos, not its stops'"
  end

  private

  def body   = @body ||= JSON.parse(response.body)
  def places = body["places"]
  def place_named(external_id) = places.find { |place| place["external_id"] == external_id }

  def stop(gtfs_id, name, island, zone)
    Stop.create!(gtfs_id: gtfs_id, name: name, island: island, zone_id: zone)
  end

  def leg(external_id, from, to, amount, vihicle, **attributes)
    FareLeg.create!({
      external_id: external_id, from_stop: from, to_stop: to, vihicle: vihicle,
      amount_min_php: amount, amount_max_php: amount, basis: "per_person",
      covers_pax: 1, fare_kind: "ticket", confidence: "reported",
      schedule_kind: "departures"
    }.merge(attributes))
  end

  def place(external_id, name, island, legs)
    place = Place.create!(external_id: external_id, name: name, island: island)
    legs.each_with_index do |fare_leg, index|
      PlaceAccessLeg.create!(place: place, fare_leg: fare_leg, option: "A", seq: index + 1)
    end
  end
end
