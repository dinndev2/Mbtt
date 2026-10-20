# A collected last-service-of-the-day. See the migration for why these are
# collected rather than derived from a service window.
class LastTrip < ApplicationRecord
  belongs_to :fare_leg
  belongs_to :board_stop, class_name: "Stop"

  validates :last_departure, format: { with: /\A\d{2}:\d{2}\z/, message: "must be HH:MM" }
  validates :confidence, inclusion: { in: FareLeg::CONFIDENCES }
  validates :fare_leg_id, uniqueness: { scope: :board_stop_id }

  def overnight? = overnight
end
