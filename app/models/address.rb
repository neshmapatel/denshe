class Address < ApplicationRecord
  include Ransackable
  include Searchable

  belongs_to :customer, optional: true
  has_many :shipping_orders, class_name: "Order", foreign_key: :shipping_address_id, inverse_of: :shipping_address, dependent: :nullify
  has_many :billing_orders, class_name: "Order", foreign_key: :billing_address_id, inverse_of: :billing_address, dependent: :nullify

  enum :kind, { shipping: 0, billing: 1 }

  validates :line1, :city, :state, :pin_code, :country, presence: true
  validates :pin_code, format: { with: /\A\d{6}\z/, message: "must be a 6-digit PIN code" }

  def self.search_columns
    %w[name phone line1 line2 city state pin_code customers.name customers.email]
  end

  def self.search_joins
    [ :customer ]
  end

  def to_s
    [ line1, city, state, pin_code ].compact_blank.join(", ")
  end
end
