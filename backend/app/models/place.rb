class Place < ApplicationRecord
  # Where a visitor should board to get here.
  belongs_to :stop, optional: true

  has_many :place_categories
  has_many :categories, through: :place_categories

  validates :name, presence: true
end
