# What one person pays to reach a place, for one way in, at a given party size.
#
# The point of this class is that the answer is a *range with caveats*, never a
# single number. A Masbate trip mixes a fixed ferry ticket, a bus fare quoted as
# a 40-200 band, a habal-habal you haggle for, and a boat you charter for the
# whole group. Flattening that into one peso figure would be a lie, so the
# result carries the flags the UI needs to say why the number is soft.
class FareEstimate
  Result = Struct.new(
    :option, :pax, :min_php, :max_php, :duration_min, :origin_island,
    :complete, :unpriced_legs, :lowest_confidence, :oldest_source,
    :negotiable, :group_sensitive, :legs, :fees, :local,
    keyword_init: true
  ) do
    def complete? = complete
    def negotiable? = negotiable
    # True when chartering dominates the bill, so travelling with other people
    # meaningfully changes what each person pays.
    def group_sensitive? = group_sensitive
    def exact? = complete && min_php == max_php
    def local? = local

    def to_s
      return "unknown" unless min_php
      exact? ? "₱#{min_php.to_i}" : "₱#{min_php.to_i}–#{max_php.to_i}"
    end
  end

  def self.for_place(place, pax: 1, include_optional: false, from_island: nil)
    place.access_options.map do |option|
      new(place, option: option, pax: pax,
                 include_optional: include_optional, from_island: from_island).call
    end
  end

  def initialize(place, option: "A", pax: 1, include_optional: false, from_island: nil)
    @place = place
    @option = option
    @pax = [ pax.to_i, 1 ].max
    @include_optional = include_optional
    @from_island = from_island.presence
  end

  def call
    min, max = 0, 0
    unpriced = []

    (legs + fees).each do |item|
      unless item.priced?
        unpriced << leg_label(item)
        next
      end
      low, high = item.per_person_range(@pax)
      min += low
      max += high
    end

    Result.new(
      option: @option,
      pax: @pax,
      # The island this way in silently assumes the traveller is standing on.
      # Most chains start at Masbate City; the Burias circuit starts at
      # Pasacao on the mainland. Nothing in place_access.csv states it, so it
      # is read off the first leg's departure stop. IslandConnection turns
      # this into "you are on Ticao, here is the boat to Masbate City".
      # Falls back to the place's own island where the chain cannot say -- a
      # habal-habal leg has no departure stop, because it leaves from wherever
      # you are standing. The island of the destination is the weaker answer
      # but it is still the right one to show, and it is never blank.
      origin_island: legs.first&.from_stop&.island || @place.island,
      # The traveller is already on the destination island and every crossing
      # in the chain is behind them, so the only thing left to pay is the gate.
      local: legs.empty?,
      # An estimate missing a priced leg is a floor, not a total. Reporting it
      # as a total would understate the trip, so callers get `complete: false`
      # and should show it as "from X".
      min_php: min.round(2),
      max_php: max.round(2),
      duration_min: legs.filter_map(&:duration_min).sum.presence,
      complete: unpriced.empty?,
      unpriced_legs: unpriced,
      lowest_confidence: lowest_confidence,
      oldest_source: (legs + fees).filter_map(&:valid_as_of).min,
      negotiable: legs.any?(&:negotiable?),
      group_sensitive: legs.any?(&:shared?) || fees.any?(&:shared?),
      legs: legs,
      fees: fees
    )
  end

  private

  # Filtered in memory, not with `where` -- the controller preloads these
  # associations and a fresh relation would throw the preload away, turning one
  # bundle request into a query per place per option.
  def legs
    @legs ||= join_where_traveller_is(
      @place.place_access_legs
            .select { |access| access.option == @option }
            .sort_by(&:seq)
            .map(&:fare_leg)
    )
  end

  # Every chain in place_access.csv is written from an origin it never states
  # -- Masbate City for most places, Pasacao for the Burias circuit. Read
  # literally, that sends a Ticao local to Catandayagan Falls, which is on
  # Ticao, by way of a fastcraft to Masbate City and the same fastcraft back,
  # and charges them 243 pesos for the round trip.
  #
  # So the chain is joined at the *last* point it reaches where the traveller
  # already is, and everything before that is dropped. Last rather than first
  # because a chain may touch several islands on the way, and the useful
  # question is where they can step into it, not where it first passes them.
  #
  # Doing this here rather than in the serializer is deliberate: the dropped
  # legs are fares the traveller genuinely does not pay, so they have to leave
  # the arithmetic too, not just the display.
  def join_where_traveller_is(legs)
    return legs if @from_island.blank?

    # Only a *crossing* can already have been made. An intra-island leg never
    # has been, however much its destination island matches: the boat out to
    # Buntod sandbar starts and ends on Masbate, and dropping it for a Masbate
    # traveller would leave them standing on the beach looking at the reef.
    join_at = legs.rindex { |leg|
      leg.crosses_islands? && leg.to_stop.island.casecmp?(@from_island)
    }
    join_at ? legs[(join_at + 1)..] : legs
  end

  def fees
    @fees ||= @place.place_fees.select { |fee| @include_optional || fee.required? }
  end

  # Worst confidence anywhere in the chain -- one 2018 blog figure makes the
  # whole estimate a 2018 estimate.
  def lowest_confidence
    present = (legs + fees).map(&:confidence)
    FareLeg::CONFIDENCES.reverse.find { |c| present.include?(c) }
  end

  def leg_label(item)
    item.is_a?(PlaceFee) ? item.label : item.external_id
  end
end
