class Payment < ApplicationRecord
  include Ransackable

  belongs_to :order
  belongs_to :payment_gateway

  enum :status, { pending: 0, paid: 1, failed: 2, cancelled: 3 }

  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true

  def to_s
    gateway_payment_id.presence || gateway_order_id.presence || "Payment ##{id}"
  end
end
