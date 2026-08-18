class History < ApplicationRecord
  belongs_to :user
  # histories.trip_id is the foreign key, so this is a belongs_to -- the old
  # has_one pointed the association the wrong way round.
  belongs_to :trip
  has_one :vihicle, through: :trip
end
