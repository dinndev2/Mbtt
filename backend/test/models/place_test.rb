require "test_helper"

class PlaceTest < ActiveSupport::TestCase
  test "can belong to several categories" do
    places(:one).categories << categories(:two)

    assert_equal [ "City", "Sea" ], places(:one).categories.map(&:name).sort
  end

  test "points at the stop to board for" do
    assert_equal stops(:one), places(:one).stop
    assert_includes categories(:one).places, places(:one)
  end
end
