# What one person pays to reach a place, for one way in, at a given party size.
#
# The point of this class is that the answer is a *range with caveats*, never a
# single number. A Masbate trip mixes a fixed ferry ticket, a bus fare quoted as
# a 40-200 band, a habal-habal you haggle for, and a boat you charter for the
# whole group. Flattening that into one peso figure would be a lie, so the
# result carries the flags the UI needs to say why the number is soft.
class FareEstimate
  Result = Struct.new(
    :option, :pax, :min_php, :max_php, :duration_min,
    :complete, :unpriced_legs, :lowest_confidence, :oldest_source,
    :negotiable, :group_sensitive, :legs, :fees,
    keyword_init: true
  ) do
    def complete? = complete
    def negotiable? = negotiable
    # True when chartering dominates the bill, so travelling with other people
    # meaningfully changes what each person pays.
    def group_sensitive? = group_sensitive
    def exact? = complete && min_php == max_php

    def to_s
      return "unknown" unless min_php
      exact? ? "₱#{min_php.to_i}" : "₱#{min_php.to_i}–#{max_php.to_i}"
    end
  end

  def self.for_place(place, pax: 1, include_optional: false)
    place.access_options.map do |option|
      new(place, option: option, pax: pax, include_optional: include_optional).call
    end
  end

  def initialize(place, option: "A", pax: 1, include_optional: false)
    @place = place
    @option = option
    @pax = [ pax.to_i, 1 ].max
    @include_optional = include_optional
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
    @legs ||= @place.place_access_legs
                    .select { |access| access.option == @option }
                    .sort_by(&:seq)
                    .map(&:fare_leg)
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
