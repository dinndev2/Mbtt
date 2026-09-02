class VihicleSerializer < ApplicationSerializer
  def as_json(*)
    {
      id: record.id,
      name: record.name,
      route_type: record.route_type
    }
  end
end
