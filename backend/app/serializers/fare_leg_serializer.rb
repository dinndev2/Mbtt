class FareLegSerializer < ApplicationSerializer
  def as_json(*)
    {
      id: record.external_id,
      mode: record.vihicle&.name,
      # Which way round the hop is being ridden. A leg is stored one way, but
      # a crossing *towards* Masbate City rides the same row backwards, so
      # from and to swap and the times come from the return timetable. See
      # IslandConnection::Hop.
      direction: direction,
      from: origin&.name,
      to: destination&.name,
      from_island: origin&.island,
      to_island: destination&.island,
      # Ids rather than nested objects: the bundle sends the stop directory
      # once under `stops`, and a leg appears in many estimates. Look the
      # terminal detail up there.
      from_stop_id: origin&.gtfs_id,
      to_stop_id: destination&.gtfs_id,
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
      # HH:MM, earliest first, for the direction being ridden. Empty for
      # anything that is not a real timetable -- a bus that leaves when it
      # fills has operating hours, and inventing departures for it is the
      # failure that strands someone.
      departures: record.departures(direction),
      service_start: record.service_start,
      service_end: record.service_end,
      headway_min: record.headway_min,
      schedule_kind: record.schedule_kind,
      # How far to trust the *timetable* for this hop, as opposed to the fare.
      # Null where no GTFS route is priced by this leg. Nothing in the feed is
      # `published`: every ferry time came from an aggregator or a blog.
      schedule: schedule
    }
  end

  private

  def direction = context.fetch(:direction, :out)
  def outbound?  = direction == :out
  def origin      = outbound? ? record.from_stop : record.to_stop
  def destination = outbound? ? record.to_stop   : record.from_stop

  # Which route's timetable governs the hop, and how far to trust it, is the
  # leg's own business -- see FareLeg#scheduling_route.
  def schedule
    route = record.scheduling_route
    return nil unless route

    {
      confidence: route.schedule_confidence,
      as_of: route.schedule_as_of,
      source_url: route.schedule_source.presence,
      note: route.schedule_note
    }
  end
end
