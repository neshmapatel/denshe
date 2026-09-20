class Customer < ApplicationRecord
  include Ransackable

  has_many :addresses, dependent: :destroy
  has_many :orders, dependent: :restrict_with_error

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def to_s
    name
  end
end
