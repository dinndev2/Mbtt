require "test_helper"

class AdvisoryTest < ActiveSupport::TestCase
  # The one piece of arithmetic in this model: the dry season runs 11-01 to
  # 04-30, so it wraps the new year and a naive between? gets December wrong.
  test "a season that wraps the new year includes both sides of it" do
    dry = Advisory.new(season_from: "11-01", season_to: "04-30")

    assert dry.in_season?(Date.new(2026, 12, 15)), "December is in the dry season"
    assert dry.in_season?(Date.new(2026, 2, 1)),   "February is in the dry season"
    assert dry.in_season?(Date.new(2026, 11, 1)),  "the first day is inclusive"
    assert dry.in_season?(Date.new(2026, 4, 30)),  "the last day is inclusive"
    assert_not dry.in_season?(Date.new(2026, 7, 1)), "July is not"
  end

  test "a season inside one year behaves normally" do
    typhoon = Advisory.new(season_from: "06-01", season_to: "11-30")

    assert typhoon.in_season?(Date.new(2026, 9, 1))
    assert_not typhoon.in_season?(Date.new(2026, 1, 1))
    assert_not typhoon.in_season?(Date.new(2026, 12, 1))
  end

  test "a note with no season applies all year" do
    cash = Advisory.new

    assert cash.year_round?
    assert cash.in_season?(Date.new(2026, 3, 3))
  end

  test "a half-filled season is rejected" do
    advisory = Advisory.new(
      external_id: "A_TEST", scope: "province", kind: "season",
      severity: "info", headline: "x", confidence: "reported",
      season_from: "11-01"
    )

    assert_not advisory.valid?
    assert_includes advisory.errors[:base].join, "both be set or both be empty"
  end

  test "warn is the severity that gets read first" do
    assert_equal %w[info plan warn].sort, Advisory::SEVERITIES.sort
  end
end
