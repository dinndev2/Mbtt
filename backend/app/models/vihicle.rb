class Vihicle < ApplicationRecord
  has_many :routes
  has_many :trips, through: :routes

  has_many :place_vihicles
  has_many :places, through: :place_vihicles

  validates :name, presence: true

  # Mirrors the GTFS route_type this mode defaults to on its routes.
  enum :route_type, { road: 3, ferry: 4 }
end
