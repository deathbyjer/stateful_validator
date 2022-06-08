class User < ApplicationRecord
  validates :email, presence: true

  def admin?
    admin
  end
end
