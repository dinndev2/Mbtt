# An IslandConnection::Result: how to get from the island the traveller is
# standing on to the island an access chain starts from.
#
# `steps` is one entry per island boundary, and each carries the ways across
# it, best first -- Ticao to Masbate has three. The client shows the first and
# offers the rest. An empty `steps` is not an error: it means no researched
# crossing exists, which is the honest answer for some pairs and worth saying
# out loud.
class IslandConnectionSerializer < ApplicationSerializer
  def as_json(*)
    {
      from_island: record.from_island,
      to_island: record.to_island,
      reachable: record.reachable?,
      hops: record.hops,
      # True when the crossings connect only on paper -- one of them lands at
      # a different pier from where the next one leaves, with nothing in the
      # data joining the two. Render this; it is the difference between a
      # journey and a pair of ferries.
      has_unresearched_transfer: record.has_unresearched_transfer?,
      steps: record.steps.map { |step| step_json(step) },
      # The gap between where the last crossing lands and where the place's
      # own access chain picks up. Null when they are the same pier.
      arrival_transfer: transfer_json(record.arrival_transfer)
    }
  end

  private

  def step_json(step)
    {
      from_island: step.from_island,
      to_island: step.to_island,
      transfer: transfer_json(step.transfer),
      crossings: step.alternatives.map { |hop|
        FareLegSerializer.one(hop.leg, direction: hop.direction)
      }
    }
  end

  # Null when this crossing leaves from the pier the last one landed at, which
  # is what a traveller assumes and what the data should only imply when true.
  def transfer_json(transfer)
    return nil unless transfer

    {
      arrive_at: StopSerializer.one(transfer.arrive_at),
      depart_from: StopSerializer.one(transfer.depart_from),
      # Same municipality is a tricycle across town; different municipalities
      # is a second journey. Say which, so the UI can pick its volume.
      same_zone: transfer.same_zone?,
      researched: transfer.researched?,
      link: FareLegSerializer.one(transfer.link)
    }
  end
end
