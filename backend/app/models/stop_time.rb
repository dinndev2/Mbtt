class StopTime < ApplicationRecord
  belongs_to :trip
  belongs_to :stop

  enum :pickup_type, { regular: 0, none: 1, phone_ahead: 2, arrange_with_driver: 3 },
       prefix: :pickup
  enum :drop_off_type, { regular: 0, none: 1, phone_ahead: 2, arrange_with_driver: 3 },
       prefix: :drop_off

  validates :stop_sequence, presence: true,
                            numericality: { only_integer: true, greater_than: 0 },
                            uniqueness: { scope: :trip_id }

  default_scope { order(:stop_sequence) }
end
