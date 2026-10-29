class AddOriginalToPlaces < ActiveRecord::Migration[8.0]
  def change
    add_column :places, :original, :boolean, default: false
  end
end
