class Trip < ApplicationRecord
  belongs_to :route
  belongs_to :service

  has_one :vihicle, through: :route
  has_many :stop_times
  has_many :stops, through: :stop_times
  # A frequency-based trip is one representative run: the vehicle leaves when
  # it fills up, so the timetable is a headway rather than a departure list.
  has_many :frequencies
  has_many :histories

  enum :direction, { outbound: 0, inbound: 1 }

  validates :gtfs_id, presence: true, uniqueness: true

  scope :frequency_based, -> { where(id: Frequency.select(:trip_id)) }

  def first_stop_time
    stop_times.first
  end

  def last_stop_time
    stop_times.last
  end

  def departure
    first_stop_time&.departure_time
  end

  def arrival
    last_stop_time&.arrival_time
  end

  # Nil until both ends of the trip have been surveyed.
  def duration_minutes
    return unless departure && arrival

    ((arrival - departure) / 60).round
  end
end
