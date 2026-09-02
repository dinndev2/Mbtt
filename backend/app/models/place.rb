class Place < ApplicationRecord
  # Where a visitor should board to get here.
  belongs_to :stop, optional: true

  has_many :place_categories, dependent: :destroy
  has_many :categories, through: :place_categories

  # The modes that can actually get a visitor here.
  has_many :place_vihicles, dependent: :destroy
  has_many :vihicles, through: :place_vihicles

  # How you get here and what it costs. See FareEstimate for the arithmetic.
  has_many :place_access_legs, dependent: :destroy
  has_many :fare_legs, through: :place_access_legs
  has_many :place_fees, dependent: :destroy
  has_many :place_images, dependent: :destroy

  scope :surveyed,     -> { where(coord_status: "verified") }
  scope :needs_survey, -> { where(coord_status: %w[needs_survey town_centroid]) }
  scope :with_images,  -> { where(id: PlaceImage.select(:place_id)) }
  scope :on_island,    ->(island) { where("LOWER(island) = ?", island.to_s.downcase) }

  # How well known a place is, measured as published coverage. Nothing here
  # counts visits, so nothing here may be called "most visited" -- the tiers
  # support "best known on Ticao" and stop there.
  TIERS = %w[anchor established documented sparse unverified].freeze
  # One source, and that source a tourism-potential study rather than anyone
  # who went. Not a destination to put in front of someone yet.
  UNVERIFIED_TIER = "unverified"

  scope :ranked,      -> { where.not(prominence_rank: nil).order(:prominence_rank) }
  scope :best_known,  ->(limit = 1) { ranked.where.not(prominence_tier: UNVERIFIED_TIER).limit(limit) }

  validates :name, presence: true
  validates :prominence_tier, inclusion: { in: TIERS }, allow_nil: true

  # The distinct ways in, in preference order -- "A" is the one to show first.
  def access_options
    place_access_legs.map(&:option).uniq.sort
  end

  def fare_estimates(pax: 1, include_optional: false)
    FareEstimate.for_place(self, pax: pax, include_optional: include_optional)
  end

  # The headline number: the cheapest complete option, falling back to the
  # cheapest incomplete one so a partially-researched place still shows a floor.
  def cheapest_estimate(pax: 1)
    estimates = fare_estimates(pax: pax)
    estimates.select(&:complete?).min_by(&:min_php) || estimates.min_by(&:min_php)
  end

  # Coordinates good enough to pin, but only `verified` is survey-grade.
  def coordinates_approximate?
    coord_status != "verified"
  end

  # True when the only trace of this place is a listing, not a visit.
  def prominence_unverified?
    prominence_tier == UNVERIFIED_TIER
  end

  # Rank among the places on the same island, so the app can say "best known on
  # Ticao" without the caller having to know the province-wide numbering.
  def island_rank
    return nil if prominence_rank.blank?

    self.class.on_island(island).ranked.pluck(:external_id).index(external_id)&.succ
  end
end
