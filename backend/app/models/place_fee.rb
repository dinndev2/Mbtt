class PlaceFee < ApplicationRecord
  belongs_to :place

  validates :external_id, presence: true, uniqueness: true
  validates :label, presence: true
  validates :basis, inclusion: { in: FareLeg::BASES }
  validates :confidence, inclusion: { in: FareLeg::CONFIDENCES }

  scope :required_only, -> { where(required: true) }
  scope :optional_extras, -> { where(required: false) }

  def priced? = amount_min_php.present?
  def shared? = basis != "per_person"

  # Same split rule as a leg -- a 300 docking fee is charged to the boat.
  def per_person_range(pax)
    return [ nil, nil ] unless priced?
    return [ amount_min_php, amount_max_php || amount_min_php ] unless shared?

    units = (pax.to_f / covers_pax).ceil
    share = ->(amount) { (amount * units / pax).round(2) }
    [ share.call(amount_min_php), share.call(amount_max_php || amount_min_php) ]
  end
end
