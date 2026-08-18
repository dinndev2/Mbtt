class AddTripReferenceToHistories < ActiveRecord::Migration[8.0]
  def change
    add_reference :histories, :trip, foreign_key: true
  end
end
