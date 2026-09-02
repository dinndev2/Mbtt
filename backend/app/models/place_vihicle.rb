class PlaceVihicle < ApplicationRecord
  belongs_to :place
  belongs_to :vihicle

  validates :vihicle_id, uniqueness: { scope: :place_id }
end
