class FareLeg < ApplicationRecord
  belongs_to :from_stop, class_name: "Stop", optional: true
  belongs_to :to_stop,   class_name: "Stop", optional: true
  belongs_to :vihicle,   optional: true

  has_many :last_trips, dependent: :destroy
  has_many :place_access_legs, dependent: :destroy
  has_many :places, through: :place_access_legs
  # The GTFS routes priced by this leg. Usually one; the leg is what the app
  # asks for a timetable's trustworthiness.
  has_many :routes

  # Whether `amount` is charged to each rider or to the whole party. This is
  # the field that makes an estimate computable: a 4,000 boat is 4,000 for a
  # solo traveller and 400 each for ten.
  BASES = %w[per_person per_boat per_vehicle].freeze
  # ticket    -- a fixed published price
  # range     -- distance-based, quoted as a band
  # negotiated-- haggled on the spot; the band is what people report paying
  # hire      -- the whole vehicle, split across the party
  KINDS = %w[ticket range negotiated hire].freeze
  # How much the figure should be trusted, in descending order.
  CONFIDENCES = %w[published reported estimate stale unknown].freeze

  validates :external_id, presence: true, uniqueness: true
  validates :basis, inclusion: { in: BASES }
  validates :fare_kind, inclusion: { in: KINDS }
  validates :confidence, inclusion: { in: CONFIDENCES }
  validates :covers_pax, numericality: { greater_than: 0 }

  # Which of the schedule columns carry anything. See README, "Schedule columns".
  SCHEDULE_KINDS = %w[departures window on_demand unknown].freeze

  scope :priced, -> { where.not(amount_min_php: nil) }
  # Legs that leave one island and land on another. These are the whole
  # connector graph -- there is no separate table of crossings, because a
  # crossing is just a leg whose two stops disagree about which island they
  # are on. Excludes legs with no `to_stop`, which land nowhere nameable.
  scope :connectors, -> {
    joins("INNER JOIN stops AS origins ON origins.id = fare_legs.from_stop_id")
      .joins("INNER JOIN stops AS destinations ON destinations.id = fare_legs.to_stop_id")
      .where.not(origins: { island: nil }).where.not(destinations: { island: nil })
      .where("origins.island != destinations.island")
  }

  def priced? = amount_min_php.present?
  def shared? = basis != "per_person"
  def negotiable? = fare_kind.in?(%w[negotiated range])

  # What one rider pays when the party is `pax` strong. A shared cost is split,
  # but only after rounding up to whole boats -- five people needing a second
  # four-seater pay for two boats, not 1.25.
  def per_person_range(pax)
    return [ nil, nil ] unless priced?
    return [ amount_min_php, amount_max_php || amount_min_php ] unless shared?

    units = (pax.to_f / covers_pax).ceil
    share = ->(amount) { (amount * units / pax).round(2) }
    [ share.call(amount_min_php), share.call(amount_max_php || amount_min_php) ]
  end

  # A leg with no `to_stop` lands somewhere the data cannot name: a provincial
  # bus fare is a distance band, a habal-habal goes wherever you point it, an
  # island-hopping charter ends where it started. Those cannot be ridden
  # backwards, and every leg that can already carries its return -- the
  # `departures` legs all have `departures_back`, and a `window` or `on_demand`
  # service runs the same hours in both directions. So reversibility needs no
  # column of its own; it is exactly whether the leg lands somewhere.
  def reversible? = to_stop_id.present?

  def crosses_islands?
    reversible? && from_stop&.island.present? && to_stop&.island.present? &&
      from_stop.island != to_stop.island
  end

  # The route whose timetable governs this hop. One leg is normally served by
  # exactly one route; where several exist, report the *least* trustworthy,
  # because one invented headway makes the whole hop a guess -- the same rule
  # FareEstimate applies to price. Nothing in the feed is `published`.
  def scheduling_route
    routes.max_by { |route| CONFIDENCES.index(route.schedule_confidence) || 99 }
  end

  # The leg's own figure wins. The GTFS route keeps its copy for feed export,
  # but fare_legs.csv is what the research pass corrects and routes.txt lags
  # behind it -- see AddScheduleProvenanceToFareLegs.
  def schedule_confidence
    self[:schedule_confidence].presence&.then { |own| own == "unknown" ? nil : own } ||
      scheduling_route&.schedule_confidence || "unknown"
  end

  # The last service of the day out of one stop, and how much to trust it.
  #
  # `basis` is the important field. `collected` came from someone who asked;
  # `timetable` was read off a real published schedule; `unknown` means nobody
  # knows and the UI must say so rather than show a time.
  LastDeparture = Struct.new(:time, :overnight, :confidence, :source_url, :basis, :note,
                             keyword_init: true) do
    def known?     = basis != :unknown
    # True when there is a clock to beat. A chartered boat is `known?` but
    # imposes no deadline, so it constrains nothing.
    def deadline?  = known? && basis != :round_trip
    def overnight? = overnight
    def to_s       = known? ? time : "unknown"
  end

  UNKNOWN_LAST_DEPARTURE = LastDeparture.new(basis: :unknown, overnight: false, confidence: "unknown").freeze

  # A chartered vehicle cannot strand you: you have hired the whole boat, it
  # waits while you are on the sandbar, and it brings you back. There is no
  # last departure to miss, which is a different thing from nobody knowing
  # when the last departure is -- and reporting it as unknown would make every
  # island-hopping trip in the province look unplannable.
  ROUND_TRIP_LAST_DEPARTURE = LastDeparture.new(
    basis: :round_trip, overnight: false, confidence: "reported",
    note: "Chartered for the trip - the boat waits and brings you back, so there is no last departure to miss. Agree the return time with the boatman."
  ).freeze

  # A timetable may be read for a last trip only when it is a real timetable.
  # A `window` service leaves when it fills: its closing hour is the shape of
  # the day, not a departure, and fourteen of these windows are `estimate`
  # -- plausible hours with an invented headway. Turning one into "last bus
  # 17:00" manufactures a departure that was never observed, and someone plans
  # their afternoon around it.
  DERIVABLE_SCHEDULE_CONFIDENCES = %w[published reported].freeze

  def last_departure_from(stop)
    return UNKNOWN_LAST_DEPARTURE if stop.nil?

    # A collected figure always wins: someone asked, and that beats both the
    # timetable and the shape of the vehicle.
    collected_last_departure(stop) ||
      (ROUND_TRIP_LAST_DEPARTURE if fare_kind == "hire") ||
      derived_last_departure(stop) ||
      UNKNOWN_LAST_DEPARTURE
  end

  # Departure times for one direction, earliest first. Empty for anything but
  # a `departures` leg -- a bus that leaves when it fills has operating hours,
  # not a timetable, and inventing one is the failure that strands someone.
  def departures(direction = :out)
    return [] unless schedule_kind == "departures"
    raw = direction == :out ? departures_out : departures_back
    raw.to_s.split(";").map(&:strip).reject(&:empty?)
  end

  # The name of the other end of this leg, read from one end of it.
  def other_end_name(stop)
    return nil if stop.nil?
    (from_stop_id == stop.id ? to_stop : from_stop)&.name
  end

  # Which way this leg is being ridden when boarded at `stop`. Nil when the
  # stop is neither end of it.
  def direction_from(stop)
    return :out  if from_stop_id == stop.id
    return :back if to_stop_id == stop.id
    nil
  end

  private

  def collected_last_departure(stop)
    trip = last_trips.find { |candidate| candidate.board_stop_id == stop.id }
    return nil unless trip

    LastDeparture.new(
      time: trip.last_departure, overnight: trip.overnight?, confidence: trip.confidence,
      source_url: trip.source_url, basis: :collected, note: trip.notes
    )
  end

  def derived_last_departure(stop)
    return nil unless schedule_kind == "departures"
    return nil unless schedule_confidence.in?(DERIVABLE_SCHEDULE_CONFIDENCES)

    direction = direction_from(stop)
    times = direction && departures(direction)
    return nil if times.blank?

    LastDeparture.new(
      time: times.max, overnight: false, confidence: schedule_confidence,
      source_url: scheduling_route&.schedule_source.presence || source_url,
      basis: :timetable,
      note: "Read off the published timetable, not asked at the pier."
    )
  end
end
