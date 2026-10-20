# One photo table for anything that has photos. Places had them first; stops
# (data/stop_images.csv) are the second owner, and a separate StopImage model
# would have been the same columns, validations and licence handling twice.
#
# The cost is the foreign key: imageable_id can point at either table, so the
# database can no longer enforce it. Every row is written by db/seeds.rb from
# a hand-checked CSV, never by a user, and `dependent: :destroy` on both
# owners covers deletes.
class MakePlaceImagesPolymorphic < ActiveRecord::Migration[8.0]
  def up
    remove_foreign_key :place_images, :places
    remove_index :place_images, name: "index_place_images_on_place_id_and_seq"
    remove_index :place_images, name: "index_place_images_on_place_id"

    rename_table :place_images, :images
    rename_column :images, :place_id, :imageable_id
    add_column :images, :imageable_type, :string

    # Every row so far is a place photo.
    execute "UPDATE images SET imageable_type = 'Place'"
    change_column_null :images, :imageable_type, false

    # What the photo shows. Matters for stops: a poblacion photo is the town,
    # not the pier, and the traveller needs to be told which.
    add_column :images, :caption, :string

    add_index :images, [ :imageable_type, :imageable_id, :seq ], unique: true
  end

  def down
    execute "DELETE FROM images WHERE imageable_type <> 'Place'"

    remove_index :images, [ :imageable_type, :imageable_id, :seq ]
    remove_column :images, :caption
    remove_column :images, :imageable_type
    rename_column :images, :imageable_id, :place_id
    rename_table :images, :place_images

    add_index :place_images, :place_id
    add_index :place_images, [ :place_id, :seq ], unique: true
    add_foreign_key :place_images, :places
  end
end
