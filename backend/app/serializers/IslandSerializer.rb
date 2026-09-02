class IslandSerializer < ApplicationSerializer
  def as_json(*)
    {
      id: record.id,
      name: record.name,
      description: record.description
    }
  end
end
