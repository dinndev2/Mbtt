# What a traveller would want to know about a terminal before going to it.
#
# `stop_desc` in the GTFS feed is one short line and empty for eleven stops,
# which is not enough to preview a pier. These columns come from data/stops.csv
# rather than from the feed, because GTFS has nowhere to put "Aroroy is not a
# RoRo port" or "San Jacinto is daytime navigation only" - facts that change
# whether a crossing is possible at all.
#
# They carry their own confidence and date, on the same rule as every other
# researched field here: thirteen of the thirty-four stops have nothing but a
# role, and an empty column is the honest record of that.
class AddTerminalDetailToStops < ActiveRecord::Migration[8.0]
  def change
    # gateway (an inter-island port) · terminal (land transport) ·
    # jump_off (where a ride or boat is arranged) · landing (where one drops you)
    add_column :stops, :role, :string
    # Who runs the pier: PPA, LGU or private. Decides who to ask when a
    # timetable is wrong.
    add_column :stops, :port_authority, :string
    # daytime | day_and_night. A daytime-only port has no evening crossing
    # however late the operator's timetable runs.
    add_column :stops, :navigation, :string
    add_column :stops, :serves, :string
    add_column :stops, :operators, :string
    add_column :stops, :facilities, :string
    add_column :stops, :ticketing, :string
    add_column :stops, :arrive_before_min, :integer
    add_column :stops, :notes, :text

    add_column :stops, :detail_confidence, :string
    add_column :stops, :detail_as_of, :date
    add_column :stops, :detail_source, :string

    add_index :stops, :role
  end
end
