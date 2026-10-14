class Voucher < ApplicationRecord
  include Ransackable

  has_many :orders, dependent: :nullify

  before_validation :normalize_offer

  validates :name, presence: true, length: { maximum: 80 }
  # greater_than on a decimal breaks the admin form. A hundredth of a percent, or a paisa, is the floor.
  validates :percent, numericality: { greater_than_or_equal_to: 0.01, less_than_or_equal_to: 100 }, allow_nil: true
  validates :discount_amount, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999 }
  validates :minimum_spend, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999 }
  validate :percent_or_amount
  validate :ends_on_or_after_start

  scope :active, -> { where(active: true) }

  def self.available(on: Date.current)
    active
      .where("starts_on IS NULL OR starts_on <= ?", on)
      .where("ends_on IS NULL OR ends_on >= ?", on)
  end

  def self.for_subtotal(amount)
    amount = amount.to_d
    available.select { |voucher| voucher.minimum_spend.to_d <= amount }
      .max_by { |voucher| [ voucher.discount_for(amount), voucher.minimum_spend.to_d ] }
  end

  def self.next_above(amount)
    amount = amount.to_d
    available.select { |voucher| voucher.minimum_spend.to_d > amount }
      .min_by { |voucher| [ voucher.minimum_spend.to_d, -voucher.discount_for(voucher.minimum_spend) ] }
  end

  def discount_for(amount)
    base = amount.to_d
    return 0.to_d if base < minimum_spend.to_d

    off = if percent.to_d.positive?
      (base * percent.to_d / 100).round(2)
    else
      discount_amount.to_d
    end
    [ off, base ].min
  end

  def percent_label
    value = percent.to_d
    number = value == value.to_i ? value.to_i : value
    "#{number}%"
  end

  def offer_label
    percent.to_d.positive? ? percent_label : nil
  end

  def to_s
    name
  end

  private

  def normalize_offer
    self.percent = nil if percent.blank? || percent.to_d.zero?
    self.discount_amount = 0 if discount_amount.blank?
  end

  def percent_or_amount
    return if percent.to_d.positive? || discount_amount.to_d.positive?

    errors.add(:percent, "or an amount off is needed")
  end

  def ends_on_or_after_start
    return if starts_on.blank? || ends_on.blank?
    return if ends_on >= starts_on

    errors.add(:ends_on, "must be on or after the start")
  end
end