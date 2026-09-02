# An operational note. Everything here is a claim about how things *usually*
# are, so the payload carries no server-computed "applies today" flag -- the
# client owns the clock, may be days offline, and evaluates `season_from`/
# `season_to` itself. A boolean baked in here would be wrong by the second day.
class AdvisorySerializer < ApplicationSerializer
  def as_json(*)
    {
      id: record.external_id,
      scope: record.scope,
      scope_ref: record.scope_ref,
      kind: record.kind,
      # info | plan | warn -- warn is the set that can cost someone the day.
      severity: record.severity,
      headline: record.headline,
      detail: record.detail,
      # MM-DD, inclusive, wrapping the new year. Both null = applies all year.
      season_from: record.season_from,
      season_to: record.season_to,
      confidence: record.confidence,
      valid_as_of: record.valid_as_of,
      source_url: record.source_url
    }
  end
end
