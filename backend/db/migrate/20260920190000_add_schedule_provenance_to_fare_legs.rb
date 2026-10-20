# The research CSV owns the timetable, so it has to own how far to trust it.
#
# `fare_legs.csv` already carried schedule_confidence, schedule_as_of,
# schedule_source and schedule_note; only the times were loaded, and the
# trustworthiness kept being read off the GTFS route instead. Those disagree
# now: the September research pass corrected R_RORO_MSB_PILAR to a published
# MARINA timetable in fare_legs.csv while routes.txt still calls it `stale`.
#
# That disagreement is not cosmetic. A last trip may only be derived from a
# timetable that is trusted, so reading the stale route confidence made the
# app report "nobody knows when the last boat leaves Pilar" about a route with
# twelve certified sailings a day.
class AddScheduleProvenanceToFareLegs < ActiveRecord::Migration[8.0]
  def change
    add_column :fare_legs, :schedule_confidence, :string, default: "unknown", null: false
    add_column :fare_legs, :schedule_as_of, :date
    add_column :fare_legs, :schedule_source, :string
    add_column :fare_legs, :schedule_note, :text
  end
end
