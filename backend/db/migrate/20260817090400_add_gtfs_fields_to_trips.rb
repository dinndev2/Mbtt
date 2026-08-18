class AddGtfsFieldsToTrips < ActiveRecord::Migration[8.0]
  def change
    add_column :trips, :gtfs_id, :string
    add_index :trips, :gtfs_id, unique: true

    add_reference :trips, :route, foreign_key: true
    add_reference :trips, :service, foreign_key: true

    add_column :trips, :headsign, :string
    # 0 = outbound, 1 = inbound
    add_column :trips, :direction, :integer, default: 0, null: false

    # The vehicle now hangs off the route, so a trip no longer carries its own.
    remove_reference :trips, :vihicle, foreign_key: true
  end
end
