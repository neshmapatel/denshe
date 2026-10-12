class Order < ApplicationRecord
  include Ransackable
  include Searchable

  belongs_to :customer, optional: true
  belongs_to :coupon, optional: true
  belongs_to :voucher, optional: true

  attr_accessor :new_customer_name, :new_customer_email, :new_customer_phone
  belongs_to :shipping_address, class_name: "Address", optional: true
  belongs_to :billing_address, class_name: "Address", optional: true
  has_many :order_items, dependent: :destroy
  has_many :payments, dependent: :destroy
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

  before_validation :create_customer_from_entry
  after_create :assign_order_number

  scope :newest_first, -> { order(created_at: :desc) }
  scope :revenue_paid, -> { where(payment_status: :payment_paid).where("payment_method IS NULL OR payment_method != ?", "owner_gift") }

  def self.search_columns
    %w[number guest_name guest_email guest_phone customers.name customers.email customers.phone]
  end

  def self.search_joins
    [ :customer ]
  end

  def to_s
    number.presence || "Order ##{id}"
  end

  def customer_display_name
    customer&.name.presence || guest_name.presence || "Guest"
  end

  def australia?
    currency == "AUD"
  end

  def payment_label
    {
      "cash" => "Collected in cash",
      "owner_gift" => "Gifted by the owner",
      "razorpay" => "Razorpay"
    }[payment_method] || payment_method
  end

  def collect_cash!
    settle_offline!(code: "cash", gateway_name: "Cash", method: "cash", reference: "Collected in cash", amount: total)
  end

  def gift_by_owner!
    settle_offline!(code: "owner_gift", gateway_name: "Gifted by the owner", method: "owner_gift", reference: "Gifted by the owner", amount: 0)
  end

  def money(amount)
    value = amount.to_d
    formatted = value == value.to_i ? value.to_i.to_s : format("%.2f", value)
    "#{australia? ? "A$" : "₹"}#{formatted}"
  end

  # Takes catalogue pieces off the shop as soon as the order is placed.
  # Safe to call again — each product is only reduced once per order.
  def reserve_catalogue_stock!
    deduct_catalogue_stock!
  end

  # Idempotent. Marks the order paid. Stock was already reserved at place.
  def capture_payment!(gateway_payment_id:, payment: nil)
    transaction do
      lock!
      if payment_paid?
        sync_paid_payment!(payment, gateway_payment_id)
        return self
      end

      sync_paid_payment!(payment, gateway_payment_id)
      update!(
        payment_status: :payment_paid,
        status: :paid,
        payment_method: "razorpay",
        payment_reference: gateway_payment_id.to_s.presence || payment_reference
      )
      deduct_catalogue_stock!
    end

    self
  end

  private

  def create_customer_from_entry
    return if customer_id.present? || customer&.persisted?
    return if new_customer_name.blank? && new_customer_email.blank? && new_customer_phone.blank?

    built = Customer.new(
      name: new_customer_name.to_s.strip,
      email: new_customer_email.to_s.strip,
      phone: new_customer_phone.to_s.strip.presence
    )
    unless built.valid?
      built.errors.full_messages.each { |message| errors.add(:base, message) }
      throw :abort
    end

    built.save!
    self.customer = built
    self.guest_name = built.name if guest_name.blank?
    self.guest_email = built.email if guest_email.blank?
    self.guest_phone = built.phone if guest_phone.blank?
  end

  def settle_offline!(code:, gateway_name:, method:, reference:, amount:)
    transaction do
      lock!
      return self if payment_paid? && payment_method == method

      gateway = PaymentGateway.find_or_create_by!(code: code) { |row| row.name = gateway_name }
      update!(
        payment_status: :payment_paid,
        status: pending? ? :paid : status,
        payment_method: method,
        payment_reference: reference
      )
      payments.create!(
        payment_gateway: gateway,
        amount: amount,
        currency: currency,
        status: :paid
      )
      deduct_catalogue_stock!
    end

    self
  end

  def assign_order_number
    return if number.present?

    update_column(:number, format("DN%04d", 1000 + id))
  end

  def sync_paid_payment!(payment, gateway_payment_id)
    return if payment.nil?

    payment.update!(
      status: :paid,
      gateway_payment_id: gateway_payment_id.to_s.presence || payment.gateway_payment_id,
      error_code: nil,
      error_message: nil,
      error_source: nil,
      error_step: nil,
      error_reason: nil
    )
  end

  def deduct_catalogue_stock!
    order_items.includes(:product).each do |item|
      product = item.product
      next if product.nil? || item.mystery_box?
      next if inventory_movements.exists?(product_id: product.id, movement_type: :customer_order)

      needed = item.quantity.to_i
      available = product.stock_quantity.to_i
      if available < needed
        raise ArgumentError, "#{product.name} is no longer available."
      end

      product.adjust_stock!(
        quantity: -needed,
        movement_type: :customer_order,
        reason: "Order #{number}",
        order: self
      )
    end
  end
end

