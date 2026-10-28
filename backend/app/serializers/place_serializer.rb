class PlaceSerializer < ApplicationSerializer
  def as_json(*)
    {
      id: record.id,
      external_id: record.external_id,
      name: record.name,
      original: record.original,
      description: record.description,
      # Decimals would otherwise serialize as strings; the map wants numbers.
      latitude: record.latitude&.to_f,
      longitude: record.longitude&.to_f,
      municipality: record.municipality,
      island: record.island,
      coord_status: record.coord_status,
      # Only `verified` is survey-grade -- the rest are municipality centroids.
      coordinates_approximate: record.coordinates_approximate?,
      travel_time_note: record.travel_time_note,
      access_note: record.access_note,
      source: record.source,
      # How well known, measured as published coverage. There is no visit
      # count anywhere in this project, so this supports "best known on Ticao"
      # and must never be rendered as "most visited". Rank is province-wide;
      # within an island-filtered bundle, sorting by it gives the island order.
      prominence: {
        rank: record.prominence_rank,
        tier: record.prominence_tier,
        source_count: record.source_count,
        basis: record.prominence_basis,
        as_of: record.prominence_as_of
      },
      categories: CategorySerializer.many(record.categories),
      vihicles: VihicleSerializer.many(record.vihicles),
      stop: StopSerializer.one(record.stop),
      images: ImageSerializer.many(record.images),
      fare_estimates: FareEstimateSerializer.many(estimates, **context)
    }
  end

  private


  # `from_island` is what makes an estimate mean anything to the person
  # holding the phone: it decides both which legs they still have to make and
  # which crossing they are shown. See FareEstimate#join_where_traveller_is.
  def estimates
    FareEstimate.for_place(
      record,
      pax: context.fetch(:pax, 1),
      from_island: context[:from_island]
    )
  end
end
