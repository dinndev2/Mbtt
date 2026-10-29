# A bundled photo of a place or a stop (`imageable`).
#
# Bundled offline. Every row carries its licence and attribution, from one of two
# sources: Wikimedia Commons files under CC BY-SA, where crediting the
# photographer is a condition of use, and open-web files with `license` set to
# "unverified", where no licence was granted at all. Either way the credit has to
# reach the UI -- for the second set it is the provenance record that says the
# photo cannot ship publicly. See data/ATTRIBUTION.md.
#
# Polymorphic rather than one table per owner, so the licence handling lives
# in one place. That gives up the database foreign key -- see the migration.
class Image < ApplicationRecord
  belongs_to :imageable, polymorphic: true

  validates :local_path, presence: true
  validates :license, presence: true
  validates :seq, numericality: { greater_than: 0 }

  # Photos uploaded from the admin form, as opposed to the bundled files above.
  # Nobody has granted a licence for them yet, so they start "unverified" like
  # the open-web set; `local_path` keeps the original filename for the record.
  has_one_attached :image
  before_validation :fill_upload_defaults, on: :create, if: -> { image.attached? }
  default_scope { order(:seq) }

  def uploaded?
    image.attached?
  end

  def credit
    [ attribution, license ].compact_blank.join(" / ")
  end

  private

  def fill_upload_defaults
    self.license ||= "unverified"
    self.local_path ||= image.filename.to_s
  end
end
