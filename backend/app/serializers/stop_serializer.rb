class StopSerializer < ApplicationSerializer
  def as_json(*)
    {
      id: record.id,
      gtfs_id: record.gtfs_id,
      name: record.name,
      latitude: record.latitude&.to_f,
      longitude: record.longitude&.to_f
    }
  end
end
