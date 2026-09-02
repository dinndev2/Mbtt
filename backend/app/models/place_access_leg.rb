# One step of one way in. `option` groups steps into an alternative route:
# option A might be the fastcraft then a habal-habal, option B the cheaper
# pumpboat then the same habal-habal.
class PlaceAccessLeg < ApplicationRecord
  belongs_to :place
  belongs_to :fare_leg

  validates :seq, numericality: { greater_than: 0 }
  validates :option, presence: true

  default_scope { order(:option, :seq) }
end
