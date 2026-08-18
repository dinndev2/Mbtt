class PlaceCategory < ApplicationRecord
  belongs_to :place
  belongs_to :category

  validates :category_id, uniqueness: { scope: :place_id }
end
