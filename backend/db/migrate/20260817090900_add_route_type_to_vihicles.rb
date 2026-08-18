class AddRouteTypeToVihicles < ActiveRecord::Migration[8.0]
  def change
    add_column :vihicles, :slug, :string
    # Default GTFS route_type for this mode: 3 for road vehicles, 4 for ferry.
    add_column :vihicles, :route_type, :integer, null: false, default: 3
    add_index :vihicles, :slug, unique: true
  end
end
