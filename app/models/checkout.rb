# Name and delivery details collected before payment. Placing the order records
# it as unpaid, takes catalogue stock off the shop, and does not charge.
class Checkout
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks

  STATES = [
    "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh",
    "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka",
    "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram",
    "Nagaland", "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu",
    "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal",
    "Andaman and Nicobar Islands", "Chandigarh", "Dadra and Nagar Haveli and Daman and Diu",
    "Delhi", "Jammu and Kashmir", "Ladakh", "Lakshadweep", "Puducherry"
  ].freeze

  AUSTRALIAN_STATES = [
    "Australian Capital Territory",
    "New South Wales",
    "Northern Territory",
    "Queensland",
    "South Australia",
    "Tasmania",
    "Victoria",
    "Western Australia"
  ].freeze

  attribute :name, :string
  attribute :phone, :string
  attribute :email, :string
  attribute :line1, :string
  attribute :line2, :string
  attribute :city, :string
  attribute :state, :string
  attribute :pin_code, :string
  attribute :billing_same, :boolean, default: true
  attribute :billing_line1, :string
  attribute :billing_line2, :string
  attribute :billing_city, :string
  attribute :billing_state, :string
  attribute :billing_pin_code, :string

  before_validation :normalize_australian_contact, if: :australia?

  validates :name, :phone, :line1, :city, :state, :pin_code, presence: true
  validates :phone, format: { with: /\A[6-9]\d{9}\z/, message: "must be a 10-digit mobile number" }, allow_blank: true, unless: :australia?
  validates :phone, format: { with: /\A(?:\+?61|0)4\d{8}\z/, message: "must be an Australian mobile number" }, allow_blank: true, if: :australia?
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :pin_code, format: { with: /\A\d{6}\z/, message: "must be a 6-digit PIN code" }, allow_blank: true, unless: :australia?
  validates :pin_code, format: { with: /\A\d{4}\z/, message: "must be a 4-digit postcode" }, allow_blank: true, if: :australia?
  validates :state, inclusion: { in: ->(checkout) { checkout.states } }, allow_blank: true
  validates :billing_line1, :billing_city, :billing_state, :billing_pin_code, presence: true, unless: :billing_same
  validates :billing_pin_code, format: { with: /\A\d{6}\z/, message: "must be a 6-digit PIN code" }, allow_blank: true, unless: ->(checkout) { checkout.billing_same || checkout.australia? }
  validates :billing_pin_code, format: { with: /\A\d{4}\z/, message: "must be a 4-digit postcode" }, allow_blank: true, if: ->(checkout) { checkout.australia? && !checkout.billing_same }
  validates :billing_state, inclusion: { in: ->(checkout) { checkout.states } }, allow_blank: true, unless: :billing_same

  attr_accessor :market

  def self.from_params(params)
    new(params.to_h.slice(*attribute_names))
  end

  def market
    @market ||= Market.india
  end

  def australia?
    market.australia?
  end

  def states
    australia? ? AUSTRALIAN_STATES : STATES
  end

  def country_name
    australia? ? "Australia" : "India"
  end

  def self.shipping_amount_for(subtotal)
    brand = Rails.application.config.x.brand
    amount = subtotal.to_d
    return 0 if amount >= brand.free_shipping_above.to_d

    brand.standard_shipping.to_d
  end

  def place!(cart)
    lines = cart.checkout_items
    if lines.empty?
      errors.add(:base, "Select a piece before checkout.")
      return
    end
    parked = cart.items.reject(&:offered?)
    if parked.any?
      names = parked.map { |line| line.product.name }
      errors.add(:base, "#{names.to_sentence} #{names.one? ? "is" : "are"} part of the India shop. Remove #{names.one? ? "it" : "them"} to place this order.")
      return
    end
    return if invalid?

    subtotal = lines.sum(&:line_total)
    shipping_amount = australia? ? 0.to_d : self.class.shipping_amount_for(subtotal)

    Order.transaction do
      shipping = Address.create!(shipping_attributes)
      billing = billing_same ? shipping : Address.create!(billing_attributes)
      order = Order.create!(
        guest_name: name.to_s.strip,
        guest_phone: phone,
        guest_email: email.presence,
        shipping_address: shipping,
        billing_address: billing,
        subtotal: subtotal,
        shipping_amount: shipping_amount,
        discount: 0,
        total: subtotal + shipping_amount,
        currency: market.currency,
        status: :pending,
        payment_status: :unpaid
      )

      lines.each do |line|
        order.order_items.create!(
          product: line.product,
          name: line.product.name,
          sku: line.product.sku,
          quantity: line.quantity,
          unit_price: line.product.price_for(market),
          item_type: :catalogue
        )
      end

      order.reserve_catalogue_stock!
      order
    rescue ArgumentError => e
      errors.add(:base, e.message)
      raise ActiveRecord::Rollback
    end.tap { |order| OrderMailer.notify_created(order) if order }
  end

  def place_mystery_box!(box, answers)
    return if invalid?

    subtotal = box[:price].to_d
    shipping_amount = self.class.shipping_amount_for(subtotal)

    Order.transaction do
      shipping = Address.create!(shipping_attributes)
      billing = billing_same ? shipping : Address.create!(billing_attributes)
      order = Order.create!(
        order_type: :mystery_box,
        guest_name: name.to_s.strip,
        guest_phone: phone,
        guest_email: email.presence,
        shipping_address: shipping,
        billing_address: billing,
        subtotal: subtotal,
        shipping_amount: shipping_amount,
        discount: 0,
        total: subtotal + shipping_amount,
        status: :pending,
        payment_status: :unpaid,
        customer_notes: answers["note"].presence
      )
      order.order_items.create!(
        name: "Mystery box, #{box[:pieces]}",
        quantity: 1,
        unit_price: box[:price],
        item_type: :mystery_box
      )
      order.create_mystery_box_preference!(
        recipient_type: answers["recipient"],
        jewellery_personality: answers["personality"],
        preferred_categories: answers["pieces"],
        preferred_finishes: answers["finish"],
        occasion: answers["occasion"],
        personal_message: answers["note"].presence,
        box_price: box[:price],
        piece_count_min: box[:min],
        piece_count_max: box[:max]
      )
      order
    end.tap { |order| OrderMailer.notify_created(order) if order }
  end

  private

  def normalize_australian_contact
    self.phone = phone.to_s.gsub(/[\s()-]/, "")
    self.pin_code = pin_code.to_s.gsub(/\s/, "")
    self.billing_pin_code = billing_pin_code.to_s.gsub(/\s/, "")
  end

  def shipping_attributes
    {
      kind: :shipping,
      name: name.to_s.strip,
      phone: phone,
      line1: line1.to_s.strip,
      line2: line2.to_s.strip.presence,
      city: city.to_s.strip,
      state: state,
      pin_code: pin_code,
      country: country_name
    }
  end

  def billing_attributes
    {
      kind: :billing,
      name: name.to_s.strip,
      phone: phone,
      line1: billing_line1.to_s.strip,
      line2: billing_line2.to_s.strip.presence,
      city: billing_city.to_s.strip,
      state: billing_state,
      pin_code: billing_pin_code,
      country: country_name
    }
  end
end
