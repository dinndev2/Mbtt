require "test_helper"

# Every chain in place_access.csv is written from an origin it never states.
# Read literally it sends a Ticao local to a Ticao waterfall by way of a
# fastcraft to Masbate City and the same fastcraft back, and charges them for
# the round trip. These tests pin the rule that stops that happening.
class FareEstimateOriginTest < ActiveSupport::TestCase
  def setup
    @ferry = Vihicle.find_or_create_by!(slug: "ferry") { |v| v.name = "Ferry"; v.route_type = :ferry }
    @boat  = Vihicle.find_or_create_by!(slug: "boat")  { |v| v.name = "Boat";  v.route_type = :ferry }

    @city_pier   = stop("F_CITY_PIER",   "City Pier",   "Masbate", "Z_CITY")
    @city_beach  = stop("F_CITY_BEACH",  "City Beach",  "Masbate", "Z_CITY")
    @city_reef   = stop("F_CITY_REEF",   "City Reef",   "Masbate", "Z_CITY")
    @island_pier = stop("F_ISLAND_PIER", "Island Pier", "Ticao",   "Z_TICAO")
    @island_town = stop("F_ISLAND_TOWN", "Island Town", "Ticao",   "Z_TICAO")

    @crossing = leg("F_CROSSING", @city_pier,   @island_pier, 243, @ferry)
    @onward   = leg("F_ONWARD",   @island_pier, @island_town, 300, @boat)
    @reef_hop = leg("F_REEF_HOP", @city_beach,  @city_reef,   500, @boat)
  end

  test "someone already on the island does not pay for the crossing to it" do
    falls = place("F_FALLS", "Island Falls", "Ticao", [ @crossing, @onward ])

    from_city   = estimate(falls, from_island: "Masbate")
    from_island = estimate(falls, from_island: "Ticao")

    assert_equal [ "F_CROSSING", "F_ONWARD" ], from_city.legs.map(&:external_id)
    assert_equal [ "F_ONWARD" ], from_island.legs.map(&:external_id),
      "the ferry onto Ticao is behind a traveller who is already on Ticao"
    assert_equal 543, from_city.min_php
    assert_equal 300, from_island.min_php, "and they must not be charged for it"
  end

  test "a leg that stays on one island is never treated as already made" do
    # The boat out to the reef starts and ends on Masbate. Dropping it for a
    # Masbate traveller leaves them on the beach looking at the water.
    reef = place("F_REEF", "City Reef", "Masbate", [ @reef_hop ])

    estimated = estimate(reef, from_island: "Masbate")

    assert_equal [ "F_REEF_HOP" ], estimated.legs.map(&:external_id)
    assert_equal 500, estimated.min_php
    assert_not estimated.local?
  end

  test "the chain is joined at the last crossing onto the traveller's island" do
    # A chain that touches the island, leaves it and comes back must be picked
    # up at the second arrival, not the first.
    back_out = leg("F_BACK_OUT", @island_pier, @city_pier,   243, @ferry)
    back_in  = leg("F_BACK_IN",  @city_pier,   @island_town, 243, @ferry)
    wanderer = place("F_WANDER", "Wanderer", "Ticao", [ @crossing, back_out, back_in, @onward ])

    estimated = estimate(wanderer, from_island: "Ticao")

    assert_equal [ "F_ONWARD" ], estimated.legs.map(&:external_id)
  end

  test "with no origin given nothing is trimmed" do
    falls = place("F_FALLS", "Island Falls", "Ticao", [ @crossing, @onward ])

    assert_equal [ "F_CROSSING", "F_ONWARD" ], estimate(falls, from_island: nil).legs.map(&:external_id)
    assert_equal [ "F_CROSSING", "F_ONWARD" ], estimate(falls, from_island: "").legs.map(&:external_id)
  end

  test "a chain that is nothing but the crossing leaves a local trip" do
    landing = place("F_LANDING", "Island Pier Town", "Ticao", [ @crossing ])

    estimated = estimate(landing, from_island: "Ticao")

    assert estimated.local?, "there is no transport left to buy"
    assert_empty estimated.legs
    assert_equal 0, estimated.min_php
    assert_equal "Ticao", estimated.origin_island,
      "with no legs to read an origin from, the place's own island is the answer"
  end

  test "origin island falls back to the place when the first leg has no stop" do
    # A habal-habal leaves from wherever you are standing, so it has no
    # departure stop and the chain cannot say which island it starts on.
    nowhere = leg("F_HABAL", nil, @island_town, 100, @boat)
    ridge   = place("F_RIDGE", "Ridge", "Ticao", [ nowhere ])

    assert_equal "Ticao", estimate(ridge, from_island: "Masbate").origin_island
  end

  private

  def stop(gtfs_id, name, island, zone)
    Stop.create!(gtfs_id: gtfs_id, name: name, island: island, zone_id: zone)
  end

  def leg(external_id, from, to, amount, vihicle)
    FareLeg.create!(
      external_id: external_id, from_stop: from, to_stop: to, vihicle: vihicle,
      amount_min_php: amount, amount_max_php: amount, basis: "per_person",
      covers_pax: 1, fare_kind: "ticket", confidence: "reported"
    )
  end

  def place(external_id, name, island, legs)
    place = Place.create!(external_id: external_id, name: name, island: island)
    legs.each_with_index do |fare_leg, index|
      PlaceAccessLeg.create!(place: place, fare_leg: fare_leg, option: "A", seq: index + 1)
    end
    place.reload
  end

  def estimate(place, from_island:)
    FareEstimate.for_place(place, pax: 1, from_island: from_island).first
  end
end
