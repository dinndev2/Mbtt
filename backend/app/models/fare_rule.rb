class FareRule < ApplicationRecord
  belongs_to :fare
  # Empty means the fare applies to every route in the zone pair.
  belongs_to :route, optional: true
end
