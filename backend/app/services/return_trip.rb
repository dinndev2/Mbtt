# The last moment you can leave a place and still get home today.
#
# Everything else in this app answers "how do I get there". This answers the
# question people are actually afraid of, which is not getting lost but getting
# stranded: the last boat off Ticao, the last van out of the terminal, the
# lighthouse whose only public boat back is tomorrow morning.
#
# The arithmetic is a backward pass over the journey home. A traveller can
# leave the place at the latest time that still makes every remaining
# connection, so each hop's own last departure is pushed back through the
# durations in front of it and the earliest of those wins:
#
#   latest start = min over hops of ( last departure of hop - travel time before it )
#
# The hop that wins is the one worth naming. "Back by 14:00" is a rule someone
# can hold in their head; "the 14:00 pumpboat off Lagundi is what decides your
# day" is one they can plan around, and can check when the pumpboat turns out
# not to run.
#
# What this deliberately will not do is invent a constraint. Twenty-six of the
# forty legs here are services that leave when they fill, and their closing
# hour is the shape of a day rather than a departure -- see FareLeg's
# DERIVABLE_SCHEDULE_CONFIDENCES. Where the last trip is unknown this says so
# and names the hop, because "we don't know when the last jeep goes" sends
# someone to ask at the terminal, while a confident 17:00 sends them to the
# beach.
class ReturnTrip
  # A hop of the journey home: one leg, boarded where the outbound alighted.
  Hop = Struct.new(:leg, :board_stop, :alight_stop, :last_departure, :latest_start, keyword_init: true) do
    def known?      = last_departure.known?
    def deadline?   = last_departure.deadline?
    def overnight?  = last_departure.overnight?
    def duration    = leg.duration_min.to_i
    # A leg with no second stop cannot be ridden backwards: a provincial bus
    # fare is a distance band, a charter circuit ends where it started. Those
    # hops are reported but constrain nothing.
    def modelled?   = board_stop.present?
  end

  Result = Struct.new(:hops, :latest_start, :binding, :overnight_hop, :unknown_hops,
                      :round_trip_hops, :unmodelled_hops, :earliest_arrival, keyword_init: true) do
    # Nil when no hop on the way home has a known last departure. Not zero, not
    # midnight -- there is no answer, and the UI has to say that.
    def known? = latest_start.present?

    # Nothing on the way home runs to a timetable, because everything on it is
    # chartered and waits. That is not an unanswered question, it is the
    # answer: there is no last trip to miss. Buntod is the case -- you have
    # hired the boat, and it takes you back when you are ready.
    def no_deadline?
      latest_start.nil? && overnight_hop.nil? &&
        unknown_hops.empty? && unmodelled_hops.empty? && round_trip_hops.any?
    end

    # The only way back is tomorrow. Bugui Point is the case this exists for.
    def overnight? = overnight_hop.present?

    # Whether someone can reach the place and get home the same day. Unknown
    # when either end of the arithmetic is missing, which is not the same as
    # "no" and must not be rendered as one.
    def same_day
      return false if overnight?
      return true  if no_deadline?
      return nil if latest_start.nil? || earliest_arrival.nil?
      latest_start > earliest_arrival
    end

    # How long you get at the place, if both ends are known.
    def time_there_min
      return nil unless latest_start && earliest_arrival
      [ latest_start - earliest_arrival, 0 ].max
    end

    def complete? = unknown_hops.empty? && unmodelled_hops.empty?
  end

  # `outbound` is the journey there, in travel order, as [leg, board_stop]
  # pairs -- the crossings first, then the place's own access chain.
  def self.for(outbound)
    new(outbound).call
  end

  def initialize(outbound)
    @outbound = outbound.reject { |leg, _stop| leg.nil? }
  end

  def call
    hops = homeward_hops
    binding_hop, latest = binding(hops)

    Result.new(
      hops: hops,
      latest_start: latest,
      binding: binding_hop,
      overnight_hop: hops.find(&:overnight?),
      unknown_hops: hops.select { |hop| hop.modelled? && !hop.known? },
      round_trip_hops: hops.select { |hop| hop.last_departure.basis == :round_trip },
      # Hops that cannot be ridden backwards at all, because the leg lands
      # nowhere the data can name -- a distance-band bus fare, a habal-habal.
      # Something still has to carry the traveller back over them, so they are
      # reported rather than quietly dropped from the journey.
      unmodelled_hops: hops.reject(&:modelled?),
      earliest_arrival: earliest_arrival
    )
  end

  private

  # The way home is the way there, reversed, boarding where you alighted.
  def homeward_hops
    @outbound.reverse.map do |leg, board_stop|
      alighting = other_end(leg, board_stop)
      Hop.new(
        leg: leg, board_stop: alighting, alight_stop: board_stop,
        last_departure: leg.last_departure_from(alighting)
      )
    end
  end

  def other_end(leg, stop)
    return nil if stop.nil?
    leg.from_stop_id == stop.id ? leg.to_stop : leg.from_stop
  end

  # Each hop's last departure, pushed back through everything that has to
  # happen before it. The earliest such moment is when you have to leave.
  def binding(hops)
    travelled = 0
    best_hop, best_time = nil, nil

    hops.each do |hop|
      if hop.deadline? && !hop.overnight?
        candidate = minutes(hop.last_departure.time) - travelled
        hop.latest_start = candidate
        if best_time.nil? || candidate < best_time
          best_hop, best_time = hop, candidate
        end
      end
      travelled += hop.duration
    end

    [ best_hop, best_time ]
  end

  # When the earliest possible run at the outbound chain gets you there. Used
  # only to say whether a day trip is possible at all, so it takes the first
  # departure of each hop and waits for connections rather than assuming they
  # line up.
  def earliest_arrival
    clock = nil

    @outbound.each do |leg, board_stop|
      departure = first_departure_after(leg, board_stop, clock)
      return nil if departure.nil?
      clock = departure + leg.duration_min.to_i
    end

    clock
  end

  # The first time this leg can be boarded at or after `clock`. A timetabled
  # service gives a real answer; a service that leaves when it fills can be
  # boarded any time inside its hours; anything else is unknown.
  def first_departure_after(leg, board_stop, clock)
    direction = board_stop && leg.direction_from(board_stop)
    floor = clock || 0

    if leg.schedule_kind == "departures" && direction
      times = leg.departures(direction).map { |time| minutes(time) }.sort
      return times.find { |time| time >= floor } || nil
    end

    if leg.service_start.present?
      opens  = minutes(leg.service_start)
      closes = leg.service_end.present? ? minutes(leg.service_end) : nil
      boarding = [ floor, opens ].max
      return nil if closes && boarding > closes
      return boarding
    end

    # On-demand with no published hours: arranged on the spot, so it adds no
    # wait we can defend putting a number on.
    clock ? floor : nil
  end

  def minutes(time)
    hours, mins = time.to_s.split(":").map(&:to_i)
    (hours * 60) + mins.to_i
  end
end
