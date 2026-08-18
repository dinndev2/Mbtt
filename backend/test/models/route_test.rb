require "test_helper"

class RouteTest < ActiveSupport::TestCase
  test "requires a short_name or a long_name" do
    route = Route.new(gtfs_id: "R_X", agency: agencies(:one), vihicle: vihicles(:one))

    assert_not route.valid?
    assert_includes route.errors[:base], "must have a short_name or a long_name"
  end

  test "name prefers the short_name" do
    assert_equal "Masbate City – Mobo", routes(:one).name

    routes(:one).short_name = "01"
    assert_equal "01", routes(:one).name
  end

  test "ferry routes carry GTFS route_type 4" do
    assert routes(:two).ferry?
    assert_equal 4, routes(:two).route_type_before_type_cast
  end
end
