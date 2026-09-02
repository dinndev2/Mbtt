class AddStructuredFares < ActiveRecord::Migration[8.0]
  def change
    # A single priceable hop. GTFS fare_attributes can only carry a flat
    # per-rider price, which covers barely half of how Masbate actually
    # charges -- boat hire is per boat, habal-habal is negotiated, and
    # provincial bus fares are quoted as a band. Those live here instead.
    create_table :fare_legs do |t|
      t.string :external_id, null: false        # matches data/fare_legs.csv leg_id
      t.references :from_stop, foreign_key: { to_table: :stops }
      t.references :to_stop, foreign_key: { to_table: :stops }
      t.references :vihicle, foreign_key: true

      t.decimal :amount_min_php, precision: 10, scale: 2
      t.decimal :amount_max_php, precision: 10, scale: 2

      # per_person | per_boat | per_vehicle -- decides whether the app divides
      # the amount by the party size or multiplies by it.
      t.string :basis, null: false
      # How many riders one unit of `amount` covers. Only meaningful when the
      # basis is per_boat or per_vehicle.
      t.integer :covers_pax, null: false, default: 1
      # ticket | range | negotiated | hire
      t.string :fare_kind, null: false

      t.integer :duration_min
      # published | reported | stale | estimate | unknown
      t.string :confidence, null: false, default: "unknown"
      t.date :valid_as_of
      t.string :source_url
      t.text :notes

      t.timestamps
    end
    add_index :fare_legs, :external_id, unique: true

    # Entrance, environmental and docking charges. Not transport, so they are
    # not legs, but they land on the same bill.
    create_table :place_fees do |t|
      t.string :external_id, null: false
      t.references :place, null: false, foreign_key: true

      t.string :label, null: false
      t.decimal :amount_min_php, precision: 10, scale: 2
      t.decimal :amount_max_php, precision: 10, scale: 2
      t.string :basis, null: false
      t.integer :covers_pax, null: false, default: 1
      # Optional extras (guide, snorkel gear, tent) stay out of the base estimate.
      t.boolean :required, null: false, default: true

      t.string :confidence, null: false, default: "unknown"
      t.date :valid_as_of
      t.string :source_url
      t.text :notes

      t.timestamps
    end
    add_index :place_fees, :external_id, unique: true

    # An ordered chain of legs that gets you to a place. `option` groups the
    # chain: A and B are alternative ways in, not consecutive steps.
    create_table :place_access_legs do |t|
      t.references :place, null: false, foreign_key: true
      t.references :fare_leg, null: false, foreign_key: true
      t.string :option, null: false, default: "A"
      t.integer :seq, null: false
      t.string :notes

      t.timestamps
    end
    add_index :place_access_legs, [ :place_id, :option, :seq ], unique: true

    # Bundled for offline use, so licence and attribution travel with the file.
    create_table :place_images do |t|
      t.references :place, null: false, foreign_key: true
      t.integer :seq, null: false
      t.string :local_path, null: false
      t.string :license, null: false
      t.string :attribution
      t.string :source_page
      t.integer :bytes

      t.timestamps
    end
    add_index :place_images, [ :place_id, :seq ], unique: true
  end
end
