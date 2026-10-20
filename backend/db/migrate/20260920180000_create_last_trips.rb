# The last service of the day out of one stop, on one leg.
#
# This is the figure that decides whether a place is a day trip, and it is the
# one a timetable cannot be trusted to imply. Fourteen legs in this dataset are
# `window` services whose operating hours are, in the README's own words,
# plausible with the headway invented -- deriving "last bus 17:00" from an
# invented window produces a confident-looking time that strands someone, which
# is worse than admitting nobody knows.
#
# So a last trip is either collected here, or derived in code from a real
# timetable, or reported as unknown. It is never inferred from a window.
#
# Keyed on the stop boarded rather than a direction, because a leg is ridden
# both ways and the two ends rarely match: the last pumpboat off Masbate City
# is 13:00 and the last one off Ticao is 14:00, an hour the shared window in
# fare_legs.csv cannot express.
class CreateLastTrips < ActiveRecord::Migration[8.0]
  def change
    create_table :last_trips do |t|
      t.references :fare_leg, null: false, foreign_key: true
      t.references :board_stop, null: false, foreign_key: { to_table: :stops }
      # HH:MM wall clock at the pier. A string for the same reason the
      # departure lists are: these are never instants.
      t.string :last_departure, null: false
      # True when the "last trip" is not late in the day but the next morning.
      # Bugui Point's only public boat back is 06:00 tomorrow, which is not a
      # late departure, it is an overnight, and the difference is the whole
      # point of the field.
      t.boolean :overnight, default: false, null: false
      t.string :confidence, default: "unknown", null: false
      t.date :valid_as_of
      t.string :source_url
      t.text :notes
      t.timestamps
    end

    add_index :last_trips, [ :fare_leg_id, :board_stop_id ], unique: true
  end
end
