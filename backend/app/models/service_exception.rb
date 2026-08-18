class ServiceException < ApplicationRecord
  belongs_to :service

  enum :exception_type, { added: 1, removed: 2 }

  validates :date, presence: true, uniqueness: { scope: :service_id }
end
