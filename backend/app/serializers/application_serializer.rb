# Base for the hand-rolled serializers. Each subclass owns the exact shape of
# one record; the API never leaks a model's full column list by accident.
#
# `context` carries request-scoped inputs down the tree -- party size is the
# one that matters, because a fare estimate is meaningless without it.
class ApplicationSerializer
  def self.many(records, **context)
    records.map { |record| new(record, **context).as_json }
  end

  def self.one(record, **context)
    record && new(record, **context).as_json
  end

  def initialize(record, **context)
    @record = record
    @context = context
  end

  private

  attr_reader :record, :context
end
