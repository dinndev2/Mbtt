class AddStopReferenceToFares < ActiveRecord::Migration[8.0]
  def change
    add_reference :fares, :stop, foreign_key: true
  end
end
