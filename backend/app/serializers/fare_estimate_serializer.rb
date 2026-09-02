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
      legs: FareLegSerializer.many(record.legs),
      fees: record.fees.map do |fee|
        { label: fee.label, amount_min_php: fee.amount_min_php&.to_f,
          amount_max_php: fee.amount_max_php&.to_f, basis: fee.basis,
          required: fee.required, confidence: fee.confidence }
      end
    }
  end
end
