class Frequency < ApplicationRecord
  belongs_to :trip

  validates :start_time, :end_time, presence: true
  validates :headway_secs, numericality: { only_integer: true, greater_than: 0 }
  validate :end_time_after_start_time

  # "every 15 min" -- what the app shows instead of a departure board.
  def headway_minutes
    headway_secs / 60
  end

  private

  def end_time_after_start_time
    return if start_time.blank? || end_time.blank? || end_time > start_time

    errors.add(:end_time, "must be after start_time")
  end
end
