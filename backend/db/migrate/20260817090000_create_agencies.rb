class CreateAgencies < ActiveRecord::Migration[8.0]
  def change
    create_table :agencies do |t|
      t.string :gtfs_id, null: false
      t.string :name, null: false
      t.string :url
      t.string :timezone, null: false, default: "Asia/Manila"
      t.string :lang, default: "en"
      t.string :phone
      t.string :email

      t.timestamps
    end

    add_index :agencies, :gtfs_id, unique: true
  end
end
