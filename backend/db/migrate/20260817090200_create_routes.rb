class CreateRoutes < ActiveRecord::Migration[8.0]
  def change
    create_table :routes do |t|
      t.string :gtfs_id, null: false
      t.references :agency, null: false, foreign_key: true
      # The mode ridden on this route -- GTFS carries it as the `mbtt_mode`
      # extension column, since route_type cannot express tricycle or habal.
      t.references :vihicle, null: false, foreign_key: true
      t.string :short_name
      t.string :long_name
      t.text :description
      # GTFS route_type: 3 = road vehicle, 4 = ferry.
      t.integer :route_type, null: false, default: 3
      t.string :color
      t.string :text_color

      t.timestamps
    end

    add_index :routes, :gtfs_id, unique: true
  end
end
