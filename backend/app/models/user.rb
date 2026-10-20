class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
 
  enum :commuter_type, [:local, :traveller, :admin]
  has_many :histories 
  has_secure_password

  def admin?
    commuter_type == 'admin' 
  end
end
 
