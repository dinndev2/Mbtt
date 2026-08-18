class CreateTrips < ActiveRecord::Migration[8.0]
  def change
    create_table :trips do |t|
      t.references :vihicle, null: false, foreign_key: true
      t.time :departure
      t.time :arrival

      t.timestamps
    end
  end
end