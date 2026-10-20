class ImageSerializer < ApplicationSerializer
  def as_json(*)
    {
      url: record.local_path,
      license: record.license,
      attribution: record.attribution,
      source_page: record.source_page,
      # CC BY-SA requires the credit be shown wherever the photo is.
      credit: record.credit,
      # What the photo actually shows. Null for most place photos; set on stop
      # photos, where a poblacion shot is the town and not the pier.
      caption: record.caption
    }
  end
end
