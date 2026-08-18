require "test_helper"

class HistoryTest < ActiveSupport::TestCase
  test "belongs to the trip it records" do
    assert_equal trips(:one), histories(:one).trip
    assert_includes users(:one).histories, histories(:one)
  end

  test "exposes the vihicle ridden through the trip" do
    assert_equal vihicles(:one), histories(:one).vihicle
  end
end
