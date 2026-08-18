class CreateStopTimes < ActiveRecord::Migration[8.0]
  def change
    create_table :stop_times do |t|
      t.references :trip, null: false, foreign_key: true
      t.references :stop, null: false, foreign_key: true
      t.integer :stop_sequence, null: false
      # Nullable at intermediate stops, where the time is not surveyed.
      t.time :arrival_time
      t.time :departure_time
      # 0 = normal, 1 = none, 2 = phone ahead, 3 = flag down / arrange with driver
      t.integer :pickup_type, null: false, default: 0
      t.integer :drop_off_type, null: false, default: 0
      # false = the time is approximate, true = exact
      t.boolean :timepoint, null: false, default: false
      t.decimal :shape_dist_traveled, precision: 8, scale: 3

      t.timestamps
    end

    add_index :stop_times, [ :trip_id, :stop_sequence ], unique: true
  end
end
