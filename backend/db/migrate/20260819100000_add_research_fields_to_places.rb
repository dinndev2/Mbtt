class AddResearchFieldsToPlaces < ActiveRecord::Migration[8.0]
  def change
    change_table :places, bulk: true do |t|
      # Matches places.csv place_id, so a re-import upserts rather than duplicates.
      t.string :external_id
      t.string :municipality
      t.string :island
      # verified / web_sourced / needs_survey / illustrative
      t.string :coord_status
      t.string :source
      t.decimal :entrance_fee_php, precision: 8, scale: 2
      # Free text: researched fares and durations are ranges, not single figures.
      t.string :fare_note
      t.string :travel_time_note
      t.text :access_note
    end

    add_index :places, :external_id, unique: true
    add_index :places, :island
    add_index :places, :municipality

    # Which modes can get you to a place. SCOPE calls for picking a vehicle
    # once a destination is chosen, so this is a real relationship.
    create_table :place_vihicles do |t|
      t.references :place, null: false, foreign_key: true
      t.references :vihicle, null: false, foreign_key: true

      t.timestamps
    end

    add_index :place_vihicles, [ :place_id, :vihicle_id ], unique: true
  end
end
