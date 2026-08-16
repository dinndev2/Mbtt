class User < ApplicationRecord
  enum :commuter_type, [:local, :traveller]
end
