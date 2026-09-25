# Name and delivery details collected before payment. Placing the order records
# it as unpaid. No payment is taken here.
class Checkout
  include ActiveModel::Model
  include ActiveModel::Attributes

  STATES = [
    "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh",
    "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka",
    "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram",
    "Nagaland", "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu",
    "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal",
    "Andaman and Nicobar Islands", "Chandigarh", "Dadra and Nagar Haveli and Daman and Diu",
    "Delhi", "Jammu and Kashmir", "Ladakh", "Lakshadweep", "Puducherry"
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

  validates :name, :phone, :line1, :city, :state, :pin_code, presence: true
  validates :phone, format: { with: /\A[6-9]\d{9}\z/, message: "must be a 10-digit mobile number" }, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :pin_code, format: { with: /\A\d{6}\z/, message: "must be a 6-digit PIN code" }, allow_blank: true
  validates :state, inclusion: { in: STATES }, allow_blank: true
  validates :billing_line1, :billing_city, :billing_state, :billing_pin_code, presence: true, unless: :billing_same
  validates :billing_pin_code, format: { with: /\A\d{6}\z/, message: "must be a 6-digit PIN code" }, allow_blank: true, unless: :billing_same
  validates :billing_state, inclusion: { in: STATES }, allow_blank: true, unless: :billing_same

  def self.from_params(params)
    new(params.to_h.slice(*attribute_names))
  end

  def place!(cart)
    lines = cart.items
    if lines.empty?
      errors.add(:base, "Select a piece before checkout.")
      return
    end
    return if invalid?

    subtotal = lines.sum(&:line_total)

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
        shipping_amount: 0,
        discount: 0,
        total: subtotal,
        status: :pending,
        payment_status: :unpaid
      )

      lines.each do |line|
        order.order_items.create!(
          product: line.product,
          name: line.product.name,
          sku: line.product.sku,
          quantity: line.quantity,
          unit_price: line.product.selling_price,
          item_type: :catalogue
        )
      end

      order
    end
  end

  private

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
      country: "India"
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
      country: "India"
    }
  end
end
