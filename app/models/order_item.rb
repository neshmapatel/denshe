class OrderItem < ApplicationRecord
  include Ransackable

  belongs_to :order
  belongs_to :product, optional: true
  belongs_to :curated_gift, optional: true

  enum :item_type, { catalogue: 0, mystery_box: 1, combo: 2 }

  validates :name, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }
  validates :discount_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :compare_at_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_validation :refresh_discount_from_marked_price

  def capture_product_price!(product:, market:, charged:)
    charged_price = charged.to_d
    self.unit_price = charged_price
    marked = product.compare_at_for(market)&.to_d
    listed = product.price_for(market).to_d
    reference = if marked.present? && marked > charged_price
      marked
    elsif charged_price < listed
      listed
    end
    self.compare_at_price = reference if reference.present? && reference > charged_price
  end

  def line_total
    quantity * unit_price.to_d
  end

  def to_s
    "#{quantity} × #{name}"
  end

  private

  def refresh_discount_from_marked_price
    return if compare_at_price.blank?

    gap = compare_at_price.to_d - unit_price.to_d
    self.discount_amount = gap.positive? ? gap * quantity.to_i : 0
  end
end
