# A hand-written operational note -- the thing a local would tell you that no
# fare table or timetable can hold.
#
# The whole point of this model is the line it refuses to cross. "Today's 10:30
# crossing still has space" is a claim about right now: it needs a live feed,
# it cannot be cached honestly, and it strands someone when it goes stale. "The
# last pumpboat off Ticao goes about 13:00" answers the same question, ships in
# the bundle, and stays true. Only the second kind belongs here.
class Advisory < ApplicationRecord
  # province notes carry no scope_ref; the rest name what they are about by
  # natural key -- a Place#external_id, a Route#gtfs_id, an island or
  # municipality name.
  SCOPES = %w[province island municipality place route leg].freeze

  KINDS = %w[
    season tide last_departure cash permit fee
    safety connectivity access event disruption
  ].freeze

  # info -- worth knowing
  # plan -- changes what you book
  # warn -- could cost you the day or strand you
  SEVERITIES = %w[info plan warn].freeze

  # Same scale as a fare's, so one rule in the UI covers both.
  CONFIDENCES = FareLeg::CONFIDENCES

  SEASON_FORMAT = /\A\d{2}-\d{2}\z/

  validates :external_id, presence: true, uniqueness: true
  validates :scope, inclusion: { in: SCOPES }
  validates :kind, inclusion: { in: KINDS }
  validates :severity, inclusion: { in: SEVERITIES }
  validates :confidence, inclusion: { in: CONFIDENCES }
  validates :headline, presence: true
  validates :season_from, :season_to, format: { with: SEASON_FORMAT }, allow_blank: true
  validate :season_is_a_pair

  scope :province_wide, -> { where(scope: "province") }
  scope :warnings,      -> { where(severity: "warn") }
  scope :of_kind,       ->(kind) { where(kind: kind) }
  scope :for_scope,     ->(scope, ref) { where(scope: scope, scope_ref: ref) }

  # Everything a traveller heading to one island needs: the province-wide
  # notes, that island's own, the notes on places there, and every route note.
  # Route notes are not filtered by island on purpose -- a warning about the
  # crossing is exactly what someone choosing an island wants to read.
  scope :relevant_to_island, ->(island) {
    where(scope: %w[province route])
      .or(where(scope: "island").where("LOWER(scope_ref) = ?", island.to_s.downcase))
      .or(where(scope: "place", scope_ref: Place.on_island(island).select(:external_id)))
  }

  # Ordered the way they should be read: the ones that strand people first.
  scope :by_urgency, -> {
    order(Arel.sql("CASE severity WHEN 'warn' THEN 0 WHEN 'plan' THEN 1 ELSE 2 END"), :external_id)
  }

  def warning? = severity == "warn"
  def year_round? = season_from.blank? && season_to.blank?

  # Whether the note applies on `date`. A season may wrap the new year --
  # 11-01 to 04-30 is the dry season, and December is inside it.
  def in_season?(date = Date.current)
    return true if year_round?

    today = date.strftime("%m-%d")
    if season_from <= season_to
      today.between?(season_from, season_to)
    else
      today >= season_from || today <= season_to
    end
  end

  # The place or route the note is about, when it names one that exists.
  # Returns nil rather than raising -- a note may name something not yet
  # imported, which is a data gap, not an error.
  def subject
    case scope
    when "place" then Place.find_by(external_id: scope_ref)
    when "route" then Route.find_by(gtfs_id: scope_ref)
    when "leg"   then FareLeg.find_by(external_id: scope_ref)
    end
  end

  private

  def season_is_a_pair
    return if season_from.blank? == season_to.blank?

    errors.add(:base, "season_from and season_to must both be set or both be empty")
  end
end
