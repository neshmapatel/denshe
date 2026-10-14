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
  accepts_nested_attributes_for :order_items
  has_many :payments, dependent: :destroy
  has_many :inventory_movements, dependent: :nullify
  has_one :mystery_box_preference, dependent: :destroy

  enum :order_type, { standard: 0, mystery_box: 1 }
  enum :channel, { website: 0, offline: 1 }
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

  validates :subtotal, :shipping_amount, :discount, :coupon_discount, :voucher_discount, :total, numericality: { greater_than_or_equal_to: 0 }
  validates :amount_paid, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  has_secure_token :invoice_token

  before_validation :create_customer_from_entry
  before_validation :attach_customer
  before_save :refresh_totals_from_lines, prepend: true
  after_create :assign_order_number
  after_create :claim_addresses

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

  def payment_collected_text
    return "Gifted by the owner" if payment_method == "owner_gift"
    return "Not collected yet" if amount_paid.nil?

    label = payment_label.presence
    label.present? ? "#{money(amount_paid)} · #{label}" : money(amount_paid)
  end

  def payment_label
    {
      "cash" => "Collected in cash",
      "owner_gift" => "Gifted by the owner",
      "razorpay" => "Razorpay"
    }[payment_method] || payment_method
  end

  def collect_cash!
    collected = amount_paid.nil? ? total : amount_paid
    update!(amount_paid: collected) if amount_paid != collected
    settle_offline!(code: "cash", gateway_name: "Cash", method: "cash", reference: "Collected in cash", amount: collected)
  end

  def gift_by_owner!
    update!(amount_paid: 0) if amount_paid != 0
    settle_offline!(code: "owner_gift", gateway_name: "Gifted by the owner", method: "owner_gift", reference: "Gifted by the owner", amount: 0)
  end

  def coupon_summary
    return "—" if coupon_code.blank?

    parts = [ coupon_code ]
    parts << coupon.percent_label if coupon
    parts << money(coupon_discount) if coupon_discount.to_d.positive?
    parts.join(" · ")
  end

  def voucher_summary
    return "—" if voucher_name.blank?

    voucher_discount.to_d.positive? ? "#{voucher_name} · #{money(voucher_discount)}" : voucher_name
  end

  def self.backfill_customers!
    attached = 0
    where(customer_id: nil).find_each do |order|
      name = order.guest_name.to_s.strip
      phone = order.guest_phone.to_s.strip.presence
      next if name.blank? || phone.blank?

      customer = Customer.find_for_contact(email: nil, phone: phone)
      if customer.nil?
        email = order.guest_email.to_s.strip.downcase.presence
        email = nil if email.present? && Customer.where("LOWER(email) = ?", email).exists?
        customer = Customer.create!(name: name, phone: phone, email: email)
      end

      order.update_column(:customer_id, customer.id)
      ids = [ order.shipping_address_id, order.billing_address_id ].compact.uniq
      Address.where(id: ids, customer_id: nil).update_all(customer_id: customer.id) if ids.any?
      attached += 1
    end
    attached
  end

  def whatsapp_number
    raw = customer&.phone.presence || guest_phone
    digits = raw.to_s.gsub(/\D/, "")
    return if digits.blank?

    if australia?
      return digits if digits.start_with?("61")

      "61#{digits.sub(/\A0/, "")}"
    else
      return digits if digits.start_with?("91") && digits.length > 10

      "91#{digits.last(10)}"
    end
  end

  def invoice_text
    lines = [
      "Hello,",
      "",
      "Here is your DeNshe invoice for order #{number}.",
      "",
      "Total #{money(total)}"
    ]
    lines << "Amount paid #{money(amount_paid)}" unless amount_paid.nil?
    lines << ""
    lines << invoice_pdf_url
    lines.join("\n")
  end

  def invoice_pdf
    regenerate_invoice_token if invoice_token.blank?
    InvoicePdf.new(self).render
  end

  def invoice_pdf_url
    regenerate_invoice_token if invoice_token.blank?
    options = Rails.application.config.action_mailer.default_url_options || {}
    Rails.application.routes.url_helpers.invoice_url(invoice_token, format: :pdf, **options.symbolize_keys)
  end

  def invoice_whatsapp_url
    number = whatsapp_number
    return if number.blank?

    "https://wa.me/#{number}?text=#{CGI.escape(invoice_text)}"
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
        payment_reference: gateway_payment_id.to_s.presence || payment_reference,
        amount_paid: amount_paid.nil? ? total : amount_paid
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

  def attach_customer
    return if customer_id.present? || customer&.persisted?

    name = guest_name.to_s.strip
    email = guest_email.to_s.strip.downcase.presence
    phone = guest_phone.to_s.strip.presence
    return if name.blank? || (email.blank? && phone.blank?)

    found = Customer.find_for_contact(email: email, phone: phone)
    if found
      self.customer = found
      return
    end

    built = Customer.new(name: name, email: email, phone: phone)
    unless built.valid?
      built.errors.full_messages.each { |message| errors.add(:base, message) }
      throw :abort
    end

    built.save!
    self.customer = built
  end

  def claim_addresses
    return if customer_id.blank?

    ids = [ shipping_address_id, billing_address_id ].compact.uniq
    return if ids.empty?

    Address.where(id: ids, customer_id: nil).update_all(customer_id: customer_id)
  end

  def refresh_totals_from_lines
    lines_changed = order_items.any? { |item| item.will_save_change_to_unit_price? || item.will_save_change_to_quantity? }
    offers_changed = will_save_change_to_coupon_discount? || will_save_change_to_voucher_discount?

    if offers_changed && !will_save_change_to_discount?
      self.discount = coupon_discount.to_d + voucher_discount.to_d
    end

    if lines_changed && !will_save_change_to_subtotal?
      self.subtotal = order_items.sum(&:line_total)
    end

    return if will_save_change_to_total?
    return unless lines_changed || offers_changed || will_save_change_to_discount? || will_save_change_to_shipping_amount? || will_save_change_to_subtotal?

    self.total = [ subtotal.to_d - discount.to_d + shipping_amount.to_d, 0.to_d ].max
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

