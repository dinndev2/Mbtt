require "test_helper"

class FrequencyTest < ActiveSupport::TestCase
  test "reports the headway in minutes" do
    assert_equal 15, frequencies(:morning).headway_minutes
    assert_equal 30, frequencies(:midday).headway_minutes
  end

  test "end_time must be after start_time" do
    frequency = frequencies(:morning)
    frequency.end_time = frequency.start_time - 1.hour

    assert_not frequency.valid?
  end
end
