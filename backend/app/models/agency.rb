class Agency < ApplicationRecord
  has_many :routes
  has_many :fares

  validates :gtfs_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :timezone, presence: true
end
