class FareLeg < ApplicationRecord
  belongs_to :from_stop, class_name: "Stop", optional: true
  belongs_to :to_stop,   class_name: "Stop", optional: true
  belongs_to :vihicle,   optional: true

  has_many :place_access_legs, dependent: :destroy
  has_many :places, through: :place_access_legs
  # The GTFS routes priced by this leg. Usually one; the leg is what the app
  # asks for a timetable's trustworthiness.
  has_many :routes

  # Whether `amount` is charged to each rider or to the whole party. This is
  # the field that makes an estimate computable: a 4,000 boat is 4,000 for a
  # solo traveller and 400 each for ten.
  BASES = %w[per_person per_boat per_vehicle].freeze
  # ticket    -- a fixed published price
  # range     -- distance-based, quoted as a band
  # negotiated-- haggled on the spot; the band is what people report paying
  # hire      -- the whole vehicle, split across the party
  KINDS = %w[ticket range negotiated hire].freeze
  # How much the figure should be trusted, in descending order.
  CONFIDENCES = %w[published reported estimate stale unknown].freeze

  validates :external_id, presence: true, uniqueness: true
  validates :basis, inclusion: { in: BASES }
  validates :fare_kind, inclusion: { in: KINDS }
  validates :confidence, inclusion: { in: CONFIDENCES }
  validates :covers_pax, numericality: { greater_than: 0 }

  scope :priced, -> { where.not(amount_min_php: nil) }

  def priced? = amount_min_php.present?
  def shared? = basis != "per_person"
  def negotiable? = fare_kind.in?(%w[negotiated range])

  # What one rider pays when the party is `pax` strong. A shared cost is split,
  # but only after rounding up to whole boats -- five people needing a second
  # four-seater pay for two boats, not 1.25.
  def per_person_range(pax)
    return [ nil, nil ] unless priced?
    return [ amount_min_php, amount_max_php || amount_min_php ] unless shared?

    units = (pax.to_f / covers_pax).ceil
    share = ->(amount) { (amount * units / pax).round(2) }
    [ share.call(amount_min_php), share.call(amount_max_php || amount_min_php) ]
  end
end
