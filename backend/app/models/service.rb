class Service < ApplicationRecord
  has_many :trips
  has_many :service_exceptions

  DAYS = %i[monday tuesday wednesday thursday friday saturday sunday].freeze

  validates :gtfs_id, presence: true, uniqueness: true
  validates :start_date, :end_date, presence: true
  validate :end_date_after_start_date

  # Does this service run on the given date, exceptions included?
  def runs_on?(date)
    exception = service_exceptions.find_by(date: date)
    return exception.added? if exception

    return false unless date.between?(start_date, end_date)

    # Date#wday is 0 for Sunday, and DAYS[-1] is :sunday.
    public_send(DAYS[date.wday - 1])
  end

  private

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank? || end_date >= start_date

    errors.add(:end_date, "must not be before start_date")
  end
end
