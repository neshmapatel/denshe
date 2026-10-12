class Voucher < ApplicationRecord
  include Ransackable

  has_many :orders, dependent: :nullify

  validates :name, presence: true, length: { maximum: 80 }
  # greater_than on a decimal breaks the admin form. A paisa is the floor.
  validates :discount_amount, presence: true, numericality: { greater_than_or_equal_to: 0.01, less_than_or_equal_to: 999_999 }
  validates :minimum_spend, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999 }
  validate :ends_on_or_after_start

  scope :active, -> { where(active: true) }

  def self.for_subtotal(amount)
    today = Date.current
    active
      .where("starts_on IS NULL OR starts_on <= ?", today)
      .where("ends_on IS NULL OR ends_on >= ?", today)
      .where("minimum_spend <= ?", amount.to_d)
      .order(discount_amount: :desc, minimum_spend: :desc)
      .first
  end

  def discount_for(amount)
    base = amount.to_d
    return 0.to_d if base < minimum_spend.to_d

    [ discount_amount.to_d, base ].min
  end

  def to_s
    name
  end

  private

  def ends_on_or_after_start
    return if starts_on.blank? || ends_on.blank?
    return if ends_on >= starts_on

    errors.add(:ends_on, "must be on or after the start")
  end
end