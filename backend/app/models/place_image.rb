# Bundled offline. Every row carries its licence and attribution, from one of two
# sources: Wikimedia Commons files under CC BY-SA, where crediting the
# photographer is a condition of use, and open-web files with `license` set to
# "unverified", where no licence was granted at all. Either way the credit has to
# reach the UI -- for the second set it is the provenance record that says the
# photo cannot ship publicly. See data/ATTRIBUTION.md.
class PlaceImage < ApplicationRecord
  belongs_to :place

  validates :local_path, presence: true
  validates :license, presence: true
  validates :seq, numericality: { greater_than: 0 }

  default_scope { order(:seq) }

  def credit
    [ attribution, license ].compact_blank.join(" / ")
  end
end
