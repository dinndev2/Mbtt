class CreateFares < ActiveRecord::Migration[8.0]
  def change
    create_table :fares do |t|
      t.string :gtfs_id, null: false
      t.references :agency, foreign_key: true
      t.decimal :price, precision: 8, scale: 2, null: false
      t.string :currency, null: false, default: "PHP"
      # 0 = pay on board, 1 = pay before boarding
      t.integer :payment_method, null: false, default: 0
      t.integer :transfers, default: 0
      t.integer :transfer_duration

      t.timestamps
    end

    add_index :fares, :gtfs_id, unique: true

    create_table :fare_rules do |t|
      t.references :fare, null: false, foreign_key: true
      t.references :route, foreign_key: true
      # Zone names matching stops.zone_id, not stop ids -- GTFS models them as
      # opaque strings, so they stay strings here too.
      t.string :origin_zone
      t.string :destination_zone
      t.string :contains_zone

      t.timestamps
    end
  end
end
