class PlaceImageSerializer < ApplicationSerializer
  def as_json(*)
    {
      url: record.local_path,
      license: record.license,
      attribution: record.attribution,
      source_page: record.source_page,
      # CC BY-SA requires the credit be shown wherever the photo is.
      credit: record.credit
    }
  end
end
