require "test_helper"

# The graph is derived, not maintained: a crossing is any leg whose two stops
# disagree about which island they are on. These tests build a miniature
# Masbate -- two islands, a mainland, and the pier mismatch that makes the real
# Ticao-to-Burias route a trap.
class IslandConnectionTest < ActiveSupport::TestCase
  def setup
    @ferry = Vihicle.find_or_create_by!(slug: "ferry") { |v| v.name = "Ferry"; v.route_type = :ferry }

    @home_pier  = stop("T_HOME_PIER",  "Home Pier",  "Alpha", "Z_HOME")
    @hub_pier   = stop("T_HUB_PIER",   "Hub Pier",   "Beta",  "Z_HUB")
    @hub_market = stop("T_HUB_MARKET", "Hub Market", "Beta",  "Z_HUB")
    @far_pier   = stop("T_FAR_PIER",   "Far Pier",   "Beta",  "Z_FAR")
    @outer_pier = stop("T_OUTER_PIER", "Outer Pier", "Gamma", "Z_OUTER")
  end

  test "a leg whose stops sit on one island is not a crossing" do
    local = leg("T_LOCAL", @hub_pier, @hub_market)

    assert_not local.crosses_islands?
    assert_not_includes FareLeg.connectors, local
  end

  test "a leg with no destination cannot be ridden backwards" do
    # A provincial bus fare is a distance band and a charter circuit ends where
    # it started. Neither lands anywhere the data can name.
    open_ended = leg("T_OPEN", @hub_pier, nil)

    assert_not open_ended.reversible?
    assert_not open_ended.crosses_islands?
  end

  test "a crossing is found in both directions from one row" do
    leg("T_CROSS", @home_pier, @hub_pier, departures_out: "08:00", departures_back: "16:00")
    graph = IslandConnection.new

    out = graph.between("Alpha", "Beta")
    assert_equal 1, out.hops
    assert_equal "Home Pier", out.steps.first.best.origin_stop.name
    assert_equal [ "08:00" ], out.steps.first.best.departures

    back = graph.between("Beta", "Alpha")
    assert_equal "Hub Pier", back.steps.first.best.origin_stop.name
    assert_equal [ "16:00" ], back.steps.first.best.departures,
      "the return rides the same row and must read the return timetable"
  end

  test "no crossing is offered to someone already on the island" do
    leg("T_CROSS", @home_pier, @hub_pier)

    assert_nil IslandConnection.new.between("Alpha", "Alpha")
    assert_nil IslandConnection.new.between("alpha", "ALPHA"), "case must not matter"
  end

  test "alternatives across one boundary are ranked, priced and trusted first" do
    leg("T_UNPRICED", @home_pier, @hub_pier, amount_min_php: nil, confidence: "unknown")
    leg("T_STALE",    @home_pier, @hub_pier, amount_min_php: 80,  confidence: "stale")
    leg("T_GOOD",     @home_pier, @hub_pier, amount_min_php: 243, confidence: "published")

    best, second, third = IslandConnection.new.between("Alpha", "Beta").steps.first.alternatives

    assert_equal "T_GOOD",     best.leg.external_id, "a published fare outranks a cheaper stale one"
    assert_equal "T_STALE",    second.leg.external_id
    assert_equal "T_UNPRICED", third.leg.external_id, "a leg nobody has priced ranks last"
  end

  test "an island reachable only through another is found in two hops" do
    leg("T_A_TO_B", @home_pier, @hub_pier)
    leg("T_B_TO_C", @far_pier,  @outer_pier)

    route = IslandConnection.new.between("Alpha", "Gamma")

    assert route.reachable?
    assert_equal 2, route.hops
    assert_equal %w[Alpha Beta], route.steps.map(&:from_island)
  end

  test "landing at one pier and leaving from another is reported, not implied" do
    leg("T_A_TO_B", @home_pier, @hub_pier)
    leg("T_B_TO_C", @far_pier,  @outer_pier)

    transfer = IslandConnection.new.between("Alpha", "Gamma").steps.last.transfer

    assert_not_nil transfer, "two ferries that do not meet are not a route"
    assert_equal "Hub Pier", transfer.arrive_at.name
    assert_equal "Far Pier", transfer.depart_from.name
    assert_not transfer.same_zone?, "different municipalities is a second journey"
    assert_not transfer.researched?, "nothing in the data joins those two piers"
  end

  test "a gap inside one municipality is flagged but not alarming" do
    leg("T_A_TO_B", @home_pier, @hub_pier)

    route = IslandConnection.new.between("Alpha", "Beta", continuing_from: @hub_market)

    assert route.arrival_transfer.same_zone?, "both piers are in the same town"
    assert_not route.has_unresearched_transfer?,
      "a tricycle across town must not be reported as a broken journey"
  end

  test "a cross-municipality gap before the chain starts is a broken journey" do
    leg("T_A_TO_B", @home_pier, @hub_pier)

    route = IslandConnection.new.between("Alpha", "Beta", continuing_from: @far_pier)

    assert route.has_unresearched_transfer?
    assert_equal "Far Pier", route.arrival_transfer.depart_from.name
  end

  test "the cached route is not mutated by a later caller picking up elsewhere" do
    leg("T_A_TO_B", @home_pier, @hub_pier)
    graph = IslandConnection.new

    lands_where_it_starts = graph.between("Alpha", "Beta")
    graph.between("Alpha", "Beta", continuing_from: @far_pier)

    assert_nil lands_where_it_starts.arrival_transfer,
      "one place's pier mismatch must not leak into every other place's route"
  end

  test "a link is found across the municipality when not between the exact piers" do
    # The feed names Mobo Port and Mobo Poblacion separately at identical
    # coordinates, and the researched jeep runs from the poblacion. Demanding
    # the exact pier would report a broken journey across a covered town.
    hub_annex = stop("T_HUB_ANNEX", "Hub Annex", "Beta", "Z_HUB")
    leg("T_A_TO_B", @home_pier, @hub_pier)
    jeep = leg("T_ACROSS_TOWN", @far_pier, hub_annex, amount_min_php: 40)

    route = IslandConnection.new.between("Alpha", "Beta", continuing_from: @far_pier)
    transfer = route.arrival_transfer

    assert transfer.researched?, "a leg between the same two municipalities counts"
    assert_equal jeep.external_id, transfer.link.external_id
    assert_not route.has_unresearched_transfer?
  end

  test "a link is not invented between two stops in one municipality" do
    leg("T_A_TO_B", @home_pier, @hub_pier)

    transfer = IslandConnection.new.between("Alpha", "Beta", continuing_from: @hub_market).arrival_transfer

    assert_nil transfer.link, "the zone fallback must not match a leg inside one town"
    assert transfer.same_zone?, "but the short hop is still reported as harmless"
  end

  # The real case this exists for: Ticao to Burias is either the fastcraft to
  # Masbate City plus an unresearched hour down the coast to Mobo Port, or one
  # slower boat from San Jacinto straight into Mobo Port, where the Burias
  # sailing leaves. Only the second is a journey.
  def two_ways_across_one_of_which_connects
    @quick   = leg("T_QUICK",  @home_pier, @hub_pier, duration_min: 40,  confidence: "published")
    @through = leg("T_THROUGH", @home_pier, @far_pier, duration_min: 150, confidence: "reported")
    @onward  = leg("T_ONWARD", @far_pier,  @outer_pier)
  end

  test "a through boat beats a faster one that lands at the wrong pier" do
    two_ways_across_one_of_which_connects

    route = IslandConnection.new.between("Alpha", "Gamma")

    assert_equal "T_THROUGH", route.steps.first.best.leg.external_id,
      "the slower boat wins because it lands where the next one leaves"
    assert_nil route.steps.last.transfer
    assert_not route.has_unresearched_transfer?
    assert_includes route.steps.first.alternatives.map { |hop| hop.leg.external_id }, "T_QUICK",
      "the faster crossing is still offered as an alternative"
  end

  test "the return journey connects too, not just the outbound" do
    # Settling the best-ranked crossing first and working outwards gets one
    # direction right and its mirror wrong, because whichever end is fixed
    # first constrains the rest. Going the other way, the quick boat is the
    # LAST step and wins on rank, which strands the traveller at Hub Pier.
    two_ways_across_one_of_which_connects

    reverse = IslandConnection.new.between("Gamma", "Alpha")

    assert_not reverse.has_unresearched_transfer?
    assert_equal "T_THROUGH", reverse.steps.last.best.leg.external_id
    assert_equal "Far Pier", reverse.steps.first.best.destination_stop.name
  end

  test "the crossing aims at the pier the access chain picks up from" do
    # One island, two piers, and the chain starts at the far one. The quick
    # boat is the better crossing on its own merits and lands in the wrong
    # town; the slow one lands where the traveller actually needs to be.
    leg("T_QUICK",   @home_pier, @hub_pier, duration_min: 40,  confidence: "published")
    leg("T_THROUGH", @home_pier, @far_pier, duration_min: 150, confidence: "reported")

    aimed  = IslandConnection.new.between("Alpha", "Beta", continuing_from: @far_pier)
    plain  = IslandConnection.new.between("Alpha", "Beta")

    assert_equal "T_THROUGH", aimed.steps.first.best.leg.external_id
    assert_nil aimed.arrival_transfer, "it lands exactly where the chain starts"
    assert_equal "T_QUICK", plain.steps.first.best.leg.external_id,
      "with nowhere to aim at, the better crossing still wins"
  end

  test "two places on one island can want different boats" do
    leg("T_QUICK",   @home_pier, @hub_pier, duration_min: 40,  confidence: "published")
    leg("T_THROUGH", @home_pier, @far_pier, duration_min: 150, confidence: "reported")
    graph = IslandConnection.new

    to_hub = graph.between("Alpha", "Beta", continuing_from: @hub_market)
    to_far = graph.between("Alpha", "Beta", continuing_from: @far_pier)

    assert_equal "T_QUICK",   to_hub.steps.first.best.leg.external_id
    assert_equal "T_THROUGH", to_far.steps.first.best.leg.external_id,
      "the cache must key on where the chain picks up, not just the two islands"
  end

  test "an unreachable island comes back as a finding, not an exception" do
    leg("T_A_TO_B", @home_pier, @hub_pier)
    stop("T_LONE_PIER", "Lone Pier", "Delta", "Z_LONE")

    route = IslandConnection.new.between("Alpha", "Delta")

    assert_not route.reachable?
    assert_empty route.steps
  end

  private

  def stop(gtfs_id, name, island, zone)
    Stop.create!(gtfs_id: gtfs_id, name: name, island: island, zone_id: zone)
  end

  def leg(external_id, from, to, **attributes)
    FareLeg.create!({
      external_id: external_id, from_stop: from, to_stop: to, vihicle: @ferry,
      amount_min_php: 100, basis: "per_person", covers_pax: 1,
      fare_kind: "ticket", confidence: "reported", schedule_kind: "departures"
    }.merge(attributes))
  end
end
