class ExtendPlacesAndCategories < ActiveRecord::Migration[8.0]
  def change
    change_table :places, bulk: true do |t|
      t.text :description
      t.decimal :latitude, precision: 9, scale: 6
      t.decimal :longitude, precision: 9, scale: 6
      t.string :image_url
      # The boarding point a visitor should aim for to reach this place.
      t.references :stop, foreign_key: true
    end

    add_column :categories, :slug, :string
    add_column :categories, :description, :text
    add_index :categories, :slug, unique: true

    # A place can be Nature and Sea at once, so this is many-to-many.
    create_table :place_categories do |t|
      t.references :place, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end

    add_index :place_categories, [ :place_id, :category_id ], unique: true
  end
end
