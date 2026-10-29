require "test_helper"

# The fear this answers is being stranded, not being lost, so the tests are
# mostly about what the arithmetic refuses to claim.
class ReturnTripTest < ActiveSupport::TestCase
  def setup
    @ferry = Vihicle.find_or_create_by!(slug: "ferry") { |v| v.name = "Ferry"; v.route_type = :ferry }

    @home    = stop("R_HOME", "Home Pier")
    @island  = stop("R_ISLAND", "Island Pier")
    @village = stop("R_VILLAGE", "Village")
  end

  test "the last trip is the last departure boarding the far end" do
    # Ridden out you board Home Pier; ridden home you board Island Pier, and
    # the two ends of a crossing rarely run to the same clock.
    crossing = leg("R_CROSS", @home, @island, departures_out: "08:00;16:00",
                                              departures_back: "07:00;15:00")

    assert_equal "16:00", crossing.last_departure_from(@home).time
    assert_equal "15:00", crossing.last_departure_from(@island).time
  end

  test "a collected figure beats the timetable" do
    crossing = leg("R_CROSS", @home, @island, departures_back: "15:00")
    LastTrip.create!(fare_leg: crossing, board_stop: @island, last_departure: "14:00",
                     confidence: "reported", notes: "Asked at the pier.")

    last = crossing.last_departure_from(@island)

    assert_equal "14:00", last.time
    assert_equal :collected, last.basis
  end

  # The heart of it. Fourteen legs here are services that leave when they fill,
  # and their closing hour is the shape of a day, not a departure.
  test "a service window is never read as a last trip" do
    bus = leg("R_BUS", @island, @village, schedule_kind: "window",
              service_start: "06:00", service_end: "17:00", schedule_confidence: "estimate")

    last = bus.last_departure_from(@village)

    assert_not last.known?, "an invented window must not become a confident 17:00"
    assert_equal :unknown, last.basis
  end

  test "a timetable nobody trusts is not read as a last trip either" do
    stale = leg("R_STALE", @home, @island, departures_back: "13:00", schedule_confidence: "stale")

    assert_not stale.last_departure_from(@island).known?
  end

  test "the earliest deadline wins and the hop that sets it is named" do
    # Boat off the island at 15:00, jeep out of the village at 16:00 but an
    # hour's ride away - so the village jeep has to be caught by 14:00, and it
    # is the boat at 15:00 that is really the constraint... except the jeep
    # comes first on the way home.
    jeep  = leg("R_JEEP", @island, @village, duration_min: 60, departures_back: "16:00")
    boat  = leg("R_BOAT", @home, @island, duration_min: 40, departures_back: "15:00")

    # Outbound: boat Home -> Island, then jeep Island -> Village.
    result = ReturnTrip.for([ [ boat, @home ], [ jeep, @island ] ])

    # Home is jeep Village -> Island (dep by 16:00), then boat Island -> Home
    # (dep by 15:00). Catching the 15:00 boat after a 60 min jeep means leaving
    # the village by 14:00.
    assert_equal "R_BOAT", result.binding.leg.external_id
    assert_equal (14 * 60), result.latest_start
  end

  test "one unknown hop does not silence the deadlines that are known" do
    boat = leg("R_BOAT", @home, @island, duration_min: 40, departures_back: "15:00")
    walk = leg("R_HABAL", @island, @village, duration_min: 30, schedule_kind: "window",
               service_end: "18:00", schedule_confidence: "estimate")

    result = ReturnTrip.for([ [ boat, @home ], [ walk, @island ] ])

    assert_equal (14 * 60 + 30), result.latest_start, "the 15:00 boat still binds, less the habal ride"
    assert_not result.complete?
    assert_equal [ "R_HABAL" ], result.unknown_hops.map { |hop| hop.leg.external_id },
      "and the hop nobody knows is named, because that is the question to ask"
  end

  test "a chartered boat imposes no deadline and is not an unknown" do
    charter = leg("R_CHARTER", @home, @island, fare_kind: "hire", basis: "per_boat",
                  covers_pax: 6, schedule_kind: "on_demand", service_end: "17:00")

    result = ReturnTrip.for([ [ charter, @home ] ])

    assert result.no_deadline?, "you hired the boat; it waits"
    assert_nil result.latest_start
    assert_empty result.unknown_hops
    assert_equal true, result.same_day
  end

  test "an overnight return is not a late one" do
    boat = leg("R_BOAT", @home, @island, duration_min: 60, departures_back: "06:00")
    LastTrip.create!(fare_leg: boat, board_stop: @island, last_departure: "06:00",
                     overnight: true, confidence: "stale")

    result = ReturnTrip.for([ [ boat, @home ] ])

    assert result.overnight?
    assert_equal false, result.same_day, "tomorrow morning is not a same-day return"
    assert_nil result.latest_start, "there is no time today that gets you home"
  end

  test "an unanswerable question is null, never false" do
    bus = leg("R_BUS", @home, @island, schedule_kind: "window",
              service_end: "17:00", schedule_confidence: "estimate")

    result = ReturnTrip.for([ [ bus, @home ] ])

    assert_nil result.same_day, "not knowing is not the same as no, and must not render as one"
    assert_not result.no_deadline?, "nor is it the same as having no deadline"
  end

  test "a leg that lands nowhere nameable is reported, not dropped" do
    # A provincial bus fare is a distance band; something still has to carry
    # the traveller back over it.
    band = leg("R_BAND", @home, nil, schedule_kind: "window", service_end: "17:00")

    result = ReturnTrip.for([ [ band, @home ] ])

    assert_equal [ "R_BAND" ], result.unmodelled_hops.map { |hop| hop.leg.external_id }
    assert_not result.complete?
  end

  private

  def stop(gtfs_id, name)
    Stop.create!(gtfs_id: gtfs_id, name: name, island: "Alpha", zone_id: "Z_#{gtfs_id}")
  end

  def leg(external_id, from, to, **attributes)
    FareLeg.create!({
      external_id: external_id, from_stop: from, to_stop: to, vihicle: @ferry,
      amount_min_php: 100, basis: "per_person", covers_pax: 1, fare_kind: "ticket",
      confidence: "reported", schedule_kind: "departures", schedule_confidence: "reported"
    }.merge(attributes))
  end
end
