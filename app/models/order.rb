class Order < ApplicationRecord
  include Ransackable

  belongs_to :customer, optional: true
  belongs_to :shipping_address, class_name: "Address", optional: true
  belongs_to :billing_address, class_name: "Address", optional: true
  has_many :order_items, dependent: :destroy
  has_many :inventory_movements, dependent: :nullify
  has_one :mystery_box_preference, dependent: :destroy

  enum :order_type, { standard: 0, mystery_box: 1 }
  enum :status, {
    pending: 0,
    paid: 1,
    processing: 2,
    packed: 3,
    shipped: 4,
    delivered: 5,
    cancelled: 6,
    returned: 7,
    refunded: 8
  }
  enum :payment_status, { unpaid: 0, payment_pending: 1, payment_paid: 2, payment_failed: 3, payment_refunded: 4 }
  enum :shipping_status, { not_shipped: 0, packing: 1, in_transit: 2, fulfilled: 3 }

  validates :subtotal, :shipping_amount, :discount, :total, numericality: { greater_than_or_equal_to: 0 }

  after_create :assign_order_number

  scope :newest_first, -> { order(created_at: :desc) }
  scope :revenue_paid, -> { where(payment_status: :payment_paid) }

  def to_s
    number.presence || "Order ##{id}"
  end

  def customer_display_name
    customer&.name.presence || guest_name.presence || "Guest"
  end

  private

  def assign_order_number
    return if number.present?

    update_column(:number, format("DN%04d", 1000 + id))
  end
end
