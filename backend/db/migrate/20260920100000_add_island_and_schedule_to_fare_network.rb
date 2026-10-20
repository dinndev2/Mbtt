# Two things the connector graph needs that the schema had no room for.
#
# `stops.island` turns the GTFS zone into the thing the app actually reasons
# about. Every access chain in place_access.csv starts from an implicit origin
# -- Masbate City for most places, Pasacao for Burias -- and without an island
# on the stop there is no way to notice that the traveller is somewhere else.
#
# The schedule columns move the *corrected* timetables out of fare_legs.csv and
# into the table. They are deliberately not read from the GTFS feed: README's
# verify list has the feed contradicted in both directions on R_RORO_MSB_PILAR
# and running three hours too late on R_PUMP_MSB_LAGUNDI. `departures_back` is
# the return direction, which is exactly what a traveller crossing *towards*
# Masbate City needs and exactly what the feed is missing.
class AddIslandAndScheduleToFareNetwork < ActiveRecord::Migration[8.0]
  def change
    add_column :stops, :island, :string
    add_index  :stops, :island

    # `departures` legs use the two departure lists; `window` and `on_demand`
    # legs use start/end (plus headway where one was researched); `unknown`
    # uses none of them. See README, "Schedule columns".
    add_column :fare_legs, :schedule_kind, :string, default: "unknown", null: false
    # Semicolon-separated HH:MM, earliest first. Strings rather than time
    # columns: these are wall-clock times at a pier, never instants, and a
    # time column would invite a timezone that does not exist in the data.
    add_column :fare_legs, :departures_out,  :string
    add_column :fare_legs, :departures_back, :string
    add_column :fare_legs, :service_start,   :string
    add_column :fare_legs, :service_end,     :string
    add_column :fare_legs, :headway_min,     :integer
    add_column :fare_legs, :service_days,    :string
  end
end
