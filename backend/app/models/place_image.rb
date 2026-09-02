# Bundled offline. Every row carries its licence and attribution because all of
# these are Wikimedia Commons files under CC BY-SA -- crediting the photographer
# is a condition of using them, so the credit has to reach the UI.
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
