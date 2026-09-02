class FareLegSerializer < ApplicationSerializer
  def as_json(*)
    {
      id: record.external_id,
      mode: record.vihicle&.name,
      from: record.from_stop&.name,
      to: record.to_stop&.name,
      amount_min_php: record.amount_min_php&.to_f,
      amount_max_php: record.amount_max_php&.to_f,
      basis: record.basis,
      covers_pax: record.covers_pax,
      fare_kind: record.fare_kind,
      duration_min: record.duration_min,
      confidence: record.confidence,
      valid_as_of: record.valid_as_of,
      source_url: record.source_url,
      notes: record.notes,
      # How far to trust the *timetable* for this hop, as opposed to the fare.
      # Null where no GTFS route is priced by this leg. Nothing in the feed is
      # `published`: every ferry time came from an aggregator or a blog.
      schedule: schedule
    }
  end

  private

  # One leg is normally served by one route. Where several exist, report the
  # least trustworthy -- one invented headway makes the whole hop a guess, the
  # same rule FareEstimate uses for the price.
  def schedule
    route = record.routes.min_by { |r| FareLeg::CONFIDENCES.index(r.schedule_confidence) || 99 }
    return nil unless route

    {
      confidence: route.schedule_confidence,
      as_of: route.schedule_as_of,
      source_url: route.schedule_source.presence,
      note: route.schedule_note
    }
  end
end
