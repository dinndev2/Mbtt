require "test_helper"

class TripTest < ActiveSupport::TestCase
  test "departure and arrival come from the first and last stop_time" do
    trip = trips(:one)

    assert_equal "06:00:00", trip.departure.strftime("%H:%M:%S")
    assert_equal "06:25:00", trip.arrival.strftime("%H:%M:%S")
    assert_equal 25, trip.duration_minutes
  end

  test "stop_times are ordered by stop_sequence" do
    assert_equal [ 10, 20 ], trips(:one).stop_times.map(&:stop_sequence)
  end

  test "vihicle is reached through the route" do
    assert_equal vihicles(:one), trips(:one).vihicle
  end

  test "duration is unknown until both ends are surveyed" do
    assert_nil trips(:two).duration_minutes
  end

  test "frequency_based finds trips that run on a headway" do
    assert_includes Trip.frequency_based, trips(:one)
    assert_not_includes Trip.frequency_based, trips(:two)
  end
end
