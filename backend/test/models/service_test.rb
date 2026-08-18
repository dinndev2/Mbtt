require "test_helper"

class ServiceTest < ActiveSupport::TestCase
  test "weekday service runs Monday but not Sunday" do
    service = services(:weekday)

    assert service.runs_on?(Date.new(2026, 9, 7))      # Monday
    assert_not service.runs_on?(Date.new(2026, 9, 6))  # Sunday
  end

  test "daily service runs on Sunday" do
    assert services(:daily).runs_on?(Date.new(2026, 9, 6))
  end

  test "an exception overrides the weekly pattern" do
    # 2026-11-01 is a Sunday the weekday service would already skip, so pin the
    # override to a date the pattern covers.
    services(:weekday).service_exceptions.create!(date: Date.new(2026, 9, 7), exception_type: :removed)

    assert_not services(:weekday).reload.runs_on?(Date.new(2026, 9, 7))
  end

  test "does not run outside its date range" do
    assert_not services(:daily).runs_on?(Date.new(2026, 8, 1))
  end

  test "end_date must not precede start_date" do
    service = Service.new(gtfs_id: "BAD", start_date: Date.new(2026, 9, 1), end_date: Date.new(2026, 8, 1))

    assert_not service.valid?
    assert_includes service.errors[:end_date], "must not be before start_date"
  end
end
