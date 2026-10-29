class ImageSerializer < ApplicationSerializer
  def as_json(*)
    {
      # Bundled photos are served by the frontend; uploads live on this server,
      # so they need its absolute URL (see ActiveStorage::SetCurrent).
      url: record.uploaded? ? Rails.application.routes.url_helpers.rails_blob_url(record.image, **ActiveStorage::Current.url_options) : record.local_path,
      license: record.license,
      attribution: record.attribution,
      source_page: record.source_page,
      # CC BY-SA requires the credit be shown wherever the photo is.
      credit: record.credit,
      # What the photo actually shows. Null for most place photos; set on stop
      # photos, where a poblacion shot is the town and not the pier.
      caption: record.caption,
      id: record.id
    }
  end
end
