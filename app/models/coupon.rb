class Coupon < ApplicationRecord
  include Ransackable

  belongs_to :customer, optional: true
  has_many :orders, dependent: :nullify

  normalizes :code, with: ->(code) { code.to_s.strip.upcase.gsub(/\s+/, "") }

  validates :code, presence: true, uniqueness: true, length: { maximum: 32 },
                   format: { with: /\A[A-Z0-9]+(?:-[A-Z0-9]+)*\z/, message: "uses letters, numbers, and hyphens" }
  # greater_than on a decimal breaks the admin form. A hundredth of a percent is the floor.
  validates :percent, presence: true, numericality: { greater_than_or_equal_to: 0.01, less_than_or_equal_to: 100 }
  validates :uses_per_customer, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 100 }

  scope :active, -> { where(active: true) }

  def self.redeemable(code)
    normalized = code.to_s.strip.upcase.gsub(/\s+/, "")
    return if normalized.blank?

    active.where("valid_until IS NULL OR valid_until >= ?", Date.current).find_by(code: normalized)
  end

  def percent_label
    value = percent.to_d
    number = value == value.to_i ? value.to_i : value
    "#{number}%"
  end

  def discount_for(amount)
    base = amount.to_d
    return 0.to_d if base <= 0

    [ (base * percent.to_d / 100).round(2), base ].min
  end

  def for_customer?(phone:, email:, customer: nil)
    return true if customer_id.blank?

    assigned = self.customer
    return false if assigned.nil?
    return true if customer&.id == assigned.id

    key = self.class.phone_key(phone)
    assigned_key = self.class.phone_key(assigned.phone)
    return true if key.present? && assigned_key.present? && key == assigned_key

    email.present? && assigned.email.present? && email.strip.downcase == assigned.email.downcase
  end

  def available_to?(phone:, email:, customer: nil)
    uses_for(phone: phone, email: email, customer: customer) < uses_per_customer
  end

  def uses_for(phone:, email:, customer: nil)
    clauses = []
    binds = []

    if customer
      clauses << "orders.customer_id = ?"
      binds << customer.id
    end

    key = self.class.phone_key(phone)
    if key.present?
      clauses << "RIGHT(regexp_replace(COALESCE(orders.guest_phone, ''), '\\D', '', 'g'), 10) = ?"
      binds << key
    end

    if email.present?
      clauses << "LOWER(orders.guest_email) = ?"
      binds << email.strip.downcase
    end

    return 0 if clauses.empty?

    orders.where.not(status: %i[cancelled refunded]).where(clauses.join(" OR "), *binds).count
  end

  def self.phone_key(phone)
    digits = phone.to_s.gsub(/\D/, "")
    return if digits.blank?

    digits.length >= 10 ? digits.last(10) : digits
  end

  def to_s
    code
  end
end