# A FareEstimate::Result, not an AR record. The flags matter as much as the
# number -- they are what lets the UI say "from ₱930 each, cheaper in a group"
# instead of pretending ₱930 is a price.
class FareEstimateSerializer < ApplicationSerializer
  def as_json(*)
    {
      option: record.option,
      pax: record.pax,
      min_php: record.min_php&.to_f,
      max_php: record.max_php&.to_f,
      label: record.to_s,
      duration_min: record.duration_min,
      exact: record.exact?,
      complete: record.complete?,
      unpriced_legs: record.unpriced_legs,
      negotiable: record.negotiable?,
      group_sensitive: record.group_sensitive?,
      confidence: record.lowest_confidence,
      oldest_source: record.oldest_source,
      # Where this way in starts, and how to reach that from wherever the
      # traveller actually is. `connection` is null when they are already on
      # the right island, which is the common case. It is kept out of
      # min_php/max_php on purpose -- see IslandConnection.
      origin_island: record.origin_island,
      # True when the traveller is already on the destination island and there
      # is no transport left to buy -- only the gate fee, if any.
      local: record.local?,
      connection: IslandConnectionSerializer.one(connection),
      # When the last way home goes, and which hop decides it. This is the
      # question behind the fear of travelling here: not getting lost, but
      # getting stranded.
      return_trip: ReturnTripSerializer.one(return_trip),
      legs: FareLegSerializer.many(record.legs),
      fees: record.fees.map do |fee|
        { label: fee.label, amount_min_php: fee.amount_min_php&.to_f,
          amount_max_php: fee.amount_max_php&.to_f, basis: fee.basis,
          required: fee.required, confidence: fee.confidence }
      end
    }
  end

  private

  # Built once per request by the controller: the graph is four islands wide
  # and rebuilding it per option would mean a query per place per option.
  # The journey there, in travel order, as [leg, boarding stop] pairs: the
  # crossings first, then the place's own access chain. ReturnTrip reverses it.
  def return_trip
    outbound = []
    connection&.steps&.each { |step| outbound << [ step.best.leg, step.best.origin_stop ] }
    record.legs.each { |leg| outbound << [ leg, leg.from_stop ] }
    return nil if outbound.empty?

    ReturnTrip.for(outbound)
  end

  def connection
    return @connection if defined?(@connection)

    @connection = build_connection
  end

  def build_connection
    graph = context[:connections]
    return nil unless graph
    graph.between(
      context[:from_island], record.origin_island,
      # Where this option's chain actually starts, so the graph can report a
      # crossing that lands at a different pier from the one it leaves from.
      continuing_from: record.legs.first&.from_stop
    )
  end
end
