class CreateStops < ActiveRecord::Migration[8.0]
  def change
    create_table :stops do |t|
      t.string :gtfs_id, null: false
      t.string :code
      t.string :name, null: false
      t.text :description
      t.decimal :latitude, precision: 9, scale: 6
      t.decimal :longitude, precision: 9, scale: 6
      t.string :zone_id
      # 0 = boarding point, 1 = station/terminal containing several bays
      t.integer :location_type, null: false, default: 0
      t.references :parent_stop, foreign_key: { to_table: :stops }
      t.integer :wheelchair_boarding, null: false, default: 0

      t.timestamps
    end

    add_index :stops, :gtfs_id, unique: true
    add_index :stops, :zone_id
  end
end
