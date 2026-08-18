class MoveTripTimesToStopTimes < ActiveRecord::Migration[8.0]
  # stop_times now holds the authoritative times for every stop of a trip, so
  # the two columns on trips would only duplicate the first and last of them.
  # Trip#departure and Trip#arrival stay available as reader methods.
  def change
    remove_column :trips, :departure, :time
    remove_column :trips, :arrival, :time
  end
end
