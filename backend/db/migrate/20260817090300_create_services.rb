class CreateServices < ActiveRecord::Migration[8.0]
  def change
    create_table :services do |t|
      t.string :gtfs_id, null: false
      t.boolean :monday, null: false, default: false
      t.boolean :tuesday, null: false, default: false
      t.boolean :wednesday, null: false, default: false
      t.boolean :thursday, null: false, default: false
      t.boolean :friday, null: false, default: false
      t.boolean :saturday, null: false, default: false
      t.boolean :sunday, null: false, default: false
      t.date :start_date, null: false
      t.date :end_date, null: false

      t.timestamps
    end

    add_index :services, :gtfs_id, unique: true

    # calendar_dates.txt -- holidays and fiestas that break the weekly pattern.
    create_table :service_exceptions do |t|
      t.references :service, null: false, foreign_key: true
      t.date :date, null: false
      # 1 = service added on this date, 2 = service removed
      t.integer :exception_type, null: false

      t.timestamps
    end

    add_index :service_exceptions, [ :service_id, :date ], unique: true
  end
end
