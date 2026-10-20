# How someone standing on one island reaches another.
#
# This exists because every chain in place_access.csv has an *implicit* origin
# that the data never states: Masbate City for most places, Pasacao for the
# Burias circuit. That is fine for a traveller who is already there and useless
# for one who is not. A visitor on Ticao looking at Buntod sandbar needs to be
# told two things the access chain cannot tell them -- that Buntod is on
# another island, and which boat off Ticao gets them to the pier the chain
# starts from.
#
# There is no table of crossings. A crossing is just a FareLeg whose two stops
# disagree about which island they sit on, so the graph is derived rather than
# maintained, and adding a ferry to fare_legs.csv adds it to the graph for
# free. See FareLeg.connectors.
#
# What this deliberately does NOT do is fold the crossing into the place's fare
# estimate. Getting to the island and getting to the place are two decisions a
# traveller makes separately, and merging them would let one unresearched
# crossing -- Mobo to Claveria has no published fare at all -- drag an
# otherwise solid estimate down to `unknown`.
class IslandConnection
  # Masbate to Burias is one hop, Ticao to Burias is two (via Masbate City).
  # Three is slack for a route nobody has researched yet; beyond that a path
  # is a technicality, not travel advice.
  MAX_HOPS = 3

  # One leg ridden in one direction. `:out` is from_stop -> to_stop as the row
  # is written; `:back` is the return, which is the direction the GTFS feed is
  # missing on the main gateway route and the only direction that matters to
  # someone travelling towards Masbate City.
  Hop = Struct.new(:leg, :direction, keyword_init: true) do
    def outbound? = direction == :out
    def origin_stop      = outbound? ? leg.from_stop : leg.to_stop
    def destination_stop = outbound? ? leg.to_stop   : leg.from_stop
    def from_island = origin_stop.island
    def to_island   = destination_stop.island
    def departures  = leg.departures(direction)
  end

  # One island boundary, and every researched way across it -- Ticao to
  # Masbate has three (fastcraft, RoRo, pumpboat), best first.
  Step = Struct.new(:from_island, :to_island, :alternatives, :transfer, keyword_init: true) do
    def best = alternatives.first
  end

  # The gap between one crossing landing and the next one leaving. Ticao to
  # Burias lands at Masbate City Port and departs from Mobo Port -- different
  # piers in different municipalities, with nothing in the dataset joining
  # them. Reporting the two ferries and staying quiet about the hop between is
  # exactly the kind of silence that strands someone, so the gap is a field.
  Transfer = Struct.new(:arrive_at, :depart_from, :link, keyword_init: true) do
    def researched? = link.present?
    # Both stops in one municipality means a tricycle across town, which is
    # worth a line of text. Different municipalities means a second journey,
    # which is worth a warning. The zone is the municipality -- see the feed.
    def same_zone? = arrive_at.zone_id.present? && arrive_at.zone_id == depart_from.zone_id
  end

  # `steps` is one entry per island boundary crossed. Empty `steps` means no
  # researched route exists, which is a finding worth showing rather than an
  # error.
  Result = Struct.new(:from_island, :to_island, :steps, :arrival_transfer, keyword_init: true) do
    def reachable? = steps.any?
    def hops = steps.length

    def transfers
      (steps.map(&:transfer) + [ arrival_transfer ]).compact
    end

    # True when getting across involves an overland hop between municipalities
    # that nobody has researched. Every crossing can be solid and the journey
    # still not be: landing at Masbate City Port when the next boat leaves
    # from Mobo Port is two ferries and a problem, not a route.
    def has_unresearched_transfer?
      transfers.any? { |transfer| !transfer.researched? && !transfer.same_zone? }
    end
  end

  def initialize(legs = nil)
    @legs = (legs || default_legs).to_a
  end

  # nil when the traveller is already on the island -- the caller should show
  # no crossing card at all, not an empty one.
  #
  # `continuing_from` is the stop the access chain picks up at. The last
  # crossing has to land there, and often does not: the boat into Burias
  # leaves from Mobo Port, while the boat out of Ticao lands at Masbate City
  # Port, an hour down the coast. Pass it and the gap comes back named.
  def between(from_island, to_island, continuing_from: nil)
    from = normalize(from_island)
    to   = normalize(to_island)
    return nil if from.blank? || to.blank? || from == to

    # Keyed on where the chain picks up as well as the two islands, because
    # that is an input to which crossing gets chosen, not just something
    # reported afterwards -- two places on the same island can want different
    # boats. The graph is four islands wide, so the cache stays small.
    @results ||= {}
    @results[[ from, to, continuing_from&.id ]] ||= build(from, to, continuing_from)
  end

  private

  def build(from, to, continuing_from)
    steps = shortest_island_path(from, to).each_cons(2).map { |a, b|
      Step.new(from_island: island_name(a), to_island: island_name(b),
               alternatives: alternatives(a, b))
    }
    prefer_continuous(steps, continuing_from)
    # Each step after the first has to start where the one before it finished.
    # Where it does not, say so.
    steps.each_cons(2) { |previous, following| following.transfer = transfer(previous, following) }

    Result.new(
      from_island: island_name(from), to_island: island_name(to), steps: steps,
      arrival_transfer: transfer_between(steps.last&.best&.destination_stop, continuing_from)
    )
  end

  # Choose the crossings that actually meet each other, and that meet the
  # access chain waiting at the far end.
  #
  # Ticao to Burias can be the fastcraft to Masbate City and then an hour down
  # the coast to Mobo Port, or one slower boat from San Jacinto straight into
  # Mobo Port, where the Burias sailing leaves. Those are different journeys,
  # not slower and faster versions of one, and ranking each crossing on its own
  # fare and timetable cannot see the difference: the fastcraft wins every
  # local comparison and puts the traveller at the wrong pier.
  #
  # So the path is scored whole rather than step by step. Picking greedily from
  # either end gets one direction right and the mirror wrong, because whichever
  # end is settled first constrains the rest.
  #
  # The search is tiny by construction -- at most MAX_HOPS boundaries with a
  # handful of crossings each -- and capped so a larger future dataset degrades
  # to the per-crossing ranking instead of enumerating a fortune.
  MAX_COMBINATIONS = 512

  def prefer_continuous(steps, continuing_from = nil)
    return if steps.empty? || (steps.length < 2 && continuing_from.nil?)

    ranked = steps.map { |step| step.alternatives.each_with_index.to_a }
    combinations = ranked.reduce(1) { |total, alternatives| total * alternatives.length }
    return if combinations > MAX_COMBINATIONS

    best = ranked.first.product(*ranked.drop(1)).min_by { |choice| path_cost(choice, continuing_from) }
    steps.zip(best).each do |step, (hop, _rank)|
      step.alternatives = [ hop ] + (step.alternatives - [ hop ])
    end
  end

  # A pier mismatch outweighs any amount of preference between two boats, so
  # continuity is weighted far above the per-crossing ranking rather than
  # traded against it.
  def path_cost(choice, continuing_from)
    joins = choice.each_cons(2).sum { |(landing, _), (boarding, _)|
      continuity(landing.destination_stop, boarding.origin_stop)
    }
    joins += continuity(choice.last.first.destination_stop, continuing_from) if continuing_from
    joins * 100 + choice.sum { |_hop, rank| rank }
  end

  # Same pier is seamless, same municipality is a tricycle, anywhere else is a
  # second journey.
  def continuity(landing, target)
    return 0 if landing.id == target.id
    return 1 if landing.zone_id.present? && landing.zone_id == target.zone_id
    2
  end

  def transfer(previous, following)
    transfer_between(previous.best&.destination_stop, following.best&.origin_stop)
  end

  def transfer_between(arrive, depart)
    return nil if arrive.nil? || depart.nil? || arrive.id == depart.id

    Transfer.new(arrive_at: arrive, depart_from: depart, link: link_between(arrive, depart))
  end

  # A researched leg joining the two piers, if one exists. Memoised because
  # the controller asks for the same connection once per place per option, and
  # this is the only part of the graph that has to go back to the database.
  def link_between(from_stop, to_stop)
    @links ||= {}
    key = [ from_stop.id, to_stop.id ]
    return @links[key] if @links.key?(key)

    @links[key] = exact_link(from_stop, to_stop) || zone_link(from_stop, to_stop)
  end

  def exact_link(from_stop, to_stop)
    FareLeg.find_by(from_stop: from_stop, to_stop: to_stop) ||
      FareLeg.find_by(from_stop: to_stop, to_stop: from_stop)
  end

  # Falling back to the municipality is deliberate, not sloppy. The feed names
  # Mobo Port and Mobo Poblacion as separate stops at identical coordinates,
  # and the researched jeep to Masbate City runs from the poblacion. Demanding
  # the exact pier would report every arrival from Burias as a broken journey
  # across a town the dataset already covers -- a false alarm on forty routes,
  # which is the fastest way to teach someone to ignore the real ones.
  def zone_link(from_stop, to_stop)
    zones = [ from_stop.zone_id, to_stop.zone_id ]
    return nil if zones.any?(&:blank?) || zones.uniq.one?

    candidates = FareLeg
      .joins("INNER JOIN stops AS origins ON origins.id = fare_legs.from_stop_id")
      .joins("INNER JOIN stops AS destinations ON destinations.id = fare_legs.to_stop_id")
      .where("(origins.zone_id = :a AND destinations.zone_id = :b) OR " \
             "(origins.zone_id = :b AND destinations.zone_id = :a)", a: zones.first, b: zones.last)

    candidates.min_by { |leg| [ leg.priced? ? 0 : 1, FareLeg::CONFIDENCES.index(leg.confidence) || 99 ] }
  end

  def default_legs
    FareLeg.connectors.includes(:vihicle, :routes, :from_stop, :to_stop, :last_trips)
  end

  def normalize(island) = island.to_s.strip.downcase

  # Give back the island as the data spells it, so the UI says "Masbate" and
  # not whatever casing arrived in the query string.
  def island_name(key)
    @island_names ||= @legs.flat_map { |leg| [ leg.from_stop, leg.to_stop ] }
                           .compact.map(&:island).compact.uniq
                           .index_by { |name| name.downcase }
    @island_names[key] || key.capitalize
  end

  # Every crossing, in both directions, keyed by the island it leaves.
  def edges
    @edges ||= @legs.flat_map { |leg|
      [ Hop.new(leg: leg, direction: :out), Hop.new(leg: leg, direction: :back) ]
    }.select { |hop| hop.from_island.present? && hop.to_island.present? }
     .group_by { |hop| hop.from_island.downcase }
  end

  # Breadth-first, so the first path found is the one with the fewest
  # crossings. With four islands in the data this is over before it starts;
  # the bound is there so a future dataset cannot turn it into a walk.
  def shortest_island_path(from, to)
    queue = [ [ from ] ]
    seen  = Set.new([ from ])

    while (path = queue.shift)
      return path if path.last == to
      next if path.length > MAX_HOPS

      edges.fetch(path.last, []).each do |hop|
        nxt = hop.to_island.downcase
        next if seen.include?(nxt)
        seen << nxt
        queue << path + [ nxt ]
      end
    end

    []
  end

  # Every way across one boundary, best first.
  def alternatives(from, to)
    edges.fetch(from, [])
         .select { |hop| hop.to_island.downcase == to }
         .sort_by { |hop| ranking(hop) }
  end

  # What "best" means for a crossing, in order: one you can actually cost,
  # then one whose fare is trustworthy, then one whose timetable is, then the
  # quickest. Deliberately not cheapest -- the pumpboat is the cheapest way
  # off Ticao and also the one with a 2018 fare and a last sailing at 13:00.
  def ranking(hop)
    leg = hop.leg
    [
      leg.priced? ? 0 : 1,
      FareLeg::CONFIDENCES.index(leg.confidence) || 99,
      FareLeg::CONFIDENCES.index(leg.schedule_confidence) || 99,
      leg.duration_min || Float::INFINITY
    ]
  end
end
