class Route < ApplicationRecord
  belongs_to :agency
  belongs_to :vihicle

  has_many :trips
  has_many :fare_rules
  has_many :fares, through: :fare_rules

  # GTFS has no code for tricycle or habal-habal, so both ride under :road and
  # are told apart by the associated vihicle.
  enum :route_type, { road: 3, ferry: 4 }

  validates :gtfs_id, presence: true, uniqueness: true
  validate :must_have_a_name

  def name
    short_name.presence || long_name
  end

  private

  def must_have_a_name
    return if short_name.present? || long_name.present?

    errors.add(:base, "must have a short_name or a long_name")
  end
end
