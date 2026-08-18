class CreateFrequencies < ActiveRecord::Migration[8.0]
  def change
    create_table :frequencies do |t|
      t.references :trip, null: false, foreign_key: true
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.integer :headway_secs, null: false
      # false = leaves when full (tricycle, habal, jeep), true = fixed schedule
      t.boolean :exact_times, null: false, default: false

      t.timestamps
    end
  end
end
