class PaymentGateway < ApplicationRecord
  include Ransackable

  has_many :payments, dependent: :restrict_with_error

  validates :name, :code, presence: true
  validates :code, uniqueness: true

  def self.razorpay
    find_or_create_by!(code: "razorpay") { |gateway| gateway.name = "Razorpay" }
  end

  def to_s
    name
  end
end
