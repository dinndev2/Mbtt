# A terminal, as something a traveller can preview before going to it.
#
# Most of this comes from data/stops.csv rather than the GTFS feed, which has
# nowhere to record that Aroroy is not a RoRo port or that San Jacinto is
# daytime navigation only -- both of which decide whether a crossing is
# possible at all. Thirteen of the thirty-four stops carry nothing but a role,
# and those nulls are the honest record of what is published about a roadside
# arch or a village path.
class StopSerializer < ApplicationSerializer
  def as_json(*)
    {
      id: record.id,
      gtfs_id: record.gtfs_id,
      name: record.name,
      description: record.description,
      island: record.island,
      # gateway (an inter-island port) · terminal (land transport) ·
      # jump_off (where a ride or boat is arranged) · landing (where one drops you)
      role: record.role,
      latitude: record.latitude&.to_f,
      longitude: record.longitude&.to_f,
      port_authority: record.port_authority,
      # daytime | day_and_night | null. A daytime-only port has no evening
      # crossing however late the operator's timetable runs.
      navigation: record.navigation,
      serves: split(record.serves),
      operators: split(record.operators),
      facilities: split(record.facilities),
      ticketing: record.ticketing,
      arrive_before_min: record.arrive_before_min,
      notes: record.notes,
      # Null where nothing about this stop was researched, which is the state
      # for every jump-off and most poblacion terminals.
      detail: detail
    }.tap do |json|
      # Only on the bundle's stop directory, which the frontend looks every
      # stop up in. A stop nested under a place or a transfer is the same stop,
      # and repeating its photos there would mean a query per stop and the
      # same URLs over and over in the payload.
      json[:images] = ImageSerializer.many(record.images) if context[:with_images]
    end
  end

  private

  # Stored semicolon-separated for the same reason departures are: the CSV is
  # meant to be corrected by hand in a spreadsheet.
  def split(value)
    value.to_s.split(";").map(&:strip).reject(&:empty?)
  end

  def detail
    return nil if record.detail_confidence.blank?

    {
      confidence: record.detail_confidence,
      as_of: record.detail_as_of,
      source_url: record.detail_source
    }
  end
end
