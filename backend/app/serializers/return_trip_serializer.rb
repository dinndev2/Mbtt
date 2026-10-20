# A ReturnTrip::Result: the last moment you can leave and still get home.
#
# The field that matters most is `binding` -- the single hop that decides the
# day. "Back by 14:15" is a rule someone can hold in their head; "the 15:00
# fastcraft off Lagundi is what decides it" is one they can plan around and can
# check when the boat turns out not to run.
#
# `latest_start` is null when nothing on the way home runs to a timetable we
# trust. Null is not "no deadline" -- `no_deadline` is that, and it means the
# traveller has chartered the vehicle and it waits. The UI must not collapse
# the two: one says relax, the other says go and ask at the terminal.
class ReturnTripSerializer < ApplicationSerializer
  def as_json(*)
    {
      latest_start: clock(record.latest_start),
      latest_start_min: record.latest_start,
      earliest_arrival: clock(record.earliest_arrival),
      time_there_min: record.time_there_min,
      # true, false, or null for "we cannot tell" -- which must never be
      # rendered as "no".
      same_day: record.same_day,
      # There is no last trip to miss, because the boat is yours and waits.
      no_deadline: record.no_deadline?,
      # The only way back is tomorrow morning. Bugui Point.
      overnight: record.overnight?,
      complete: record.complete?,
      binding: hop(record.binding),
      # Hops on the way home where nobody knows the last departure. These are
      # the questions to ask at the terminal, and the reason the answer above
      # may be missing.
      unknown: record.unknown_hops.map { |h| hop(h) },
      # Hops that cannot be ridden backwards at all: a distance-band bus fare,
      # a habal-habal that goes wherever you point it.
      unmodelled: record.unmodelled_hops.map { |h| hop(h) },
      hops: record.hops.map { |h| hop(h) }
    }
  end

  private

  def hop(hop)
    return nil unless hop

    last = hop.last_departure
    {
      leg_id: hop.leg.external_id,
      mode: hop.leg.vihicle&.name,
      board_at: hop.board_stop&.name,
      board_stop_id: hop.board_stop&.gtfs_id,
      to: hop.alight_stop&.name,
      duration_min: hop.leg.duration_min,
      last_departure: last.known? ? last.time : nil,
      overnight: last.overnight?,
      # collected (someone asked) · timetable (read off a published schedule)
      # · round_trip (chartered, it waits) · unknown (nobody knows)
      basis: last.basis,
      confidence: last.confidence,
      source_url: last.source_url,
      note: last.note
    }
  end

  def clock(minutes)
    return nil if minutes.nil?
    format("%02d:%02d", (minutes / 60) % 24, minutes % 60)
  end
end
