class User < ApplicationRecord
  enum :commuter_type, [:local, :traveller]
  has_many :histories
end
