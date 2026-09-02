class Route < ApplicationRecord
  belongs_to :agency
  belongs_to :vihicle
  # The priced hop this timetable belongs to. It is how a fare estimate's legs
  # learn whether their departure times are real.
  belongs_to :fare_leg, optional: true

  has_many :trips
  has_many :fare_rules
  has_many :fares, through: :fare_rules

  # How far to trust the timetable, on the same scale as how far to trust the
  # fare. Nothing in this feed is `published`: every ferry time came from a
  # booking aggregator or a blog, never from the operator.
  SCHEDULE_CONFIDENCES = FareLeg::CONFIDENCES

  # GTFS has no code for tricycle or habal-habal, so both ride under :road and
  # are told apart by the associated vihicle.
  enum :route_type, { road: 3, ferry: 4 }

  validates :gtfs_id, presence: true, uniqueness: true
  validates :schedule_confidence, inclusion: { in: SCHEDULE_CONFIDENCES }
  validate :must_have_a_name

  # An `estimate` means the operating window is plausible and the headway was
  # invented; `stale` means a newer source contradicts the feed outright.
  # Neither should be shown as a departure board.
  scope :schedule_trustworthy, -> { where(schedule_confidence: %w[published reported]) }

  def schedule_trustworthy? = schedule_confidence.in?(%w[published reported])

  def name
    short_name.presence || long_name
  end

  private

  def must_have_a_name
    return if short_name.present? || long_name.present?

    errors.add(:base, "must have a short_name or a long_name")
  end
end
