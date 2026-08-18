class Fare < ApplicationRecord
  belongs_to :agency, optional: true
  belongs_to :stop, optional: true

  has_many :fare_rules
  has_many :routes, through: :fare_rules

  enum :payment_method, { on_board: 0, before_boarding: 1 }

  validates :gtfs_id, presence: true, uniqueness: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
end
