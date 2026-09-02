class CategorySerializer < ApplicationSerializer
  def as_json(*)
    {
      id: record.id,
      name: record.name,
      slug: record.slug,
      description: record.description
    }
  end
end
