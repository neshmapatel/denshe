class Address < ApplicationRecord
  include Ransackable

  belongs_to :customer, optional: true
  has_many :shipping_orders, class_name: "Order", foreign_key: :shipping_address_id, inverse_of: :shipping_address, dependent: :nullify
  has_many :billing_orders, class_name: "Order", foreign_key: :billing_address_id, inverse_of: :billing_address, dependent: :nullify

  enum :kind, { shipping: 0, billing: 1 }

  validates :line1, :city, :state, :pin_code, :country, presence: true
  validates :pin_code, format: { with: /\A\d{6}\z/, message: "must be a 6-digit PIN code" }

  def to_s
    [ line1, city, state, pin_code ].compact_blank.join(", ")
  end
end
