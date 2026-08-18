class Stop < ApplicationRecord
  # A terminal (location_type: :station) can contain several boarding bays.
  belongs_to :parent_stop, class_name: "Stop", optional: true
  has_one :fare
  has_many :child_stops, class_name: "Stop", foreign_key: :parent_stop_id

  has_many :stop_times
  has_many :trips, through: :stop_times
  has_many :places

  enum :location_type, { boarding: 0, station: 1 }
  enum :wheelchair_boarding, { unknown: 0, accessible: 1, not_accessible: 2 },
       prefix: :wheelchair

  validates :gtfs_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :latitude, inclusion: { in: -90..90 }, allow_nil: true
  validates :longitude, inclusion: { in: -180..180 }, allow_nil: true

  scope :terminals, -> { where(location_type: :station) }
end
