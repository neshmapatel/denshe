class OrderItem < ApplicationRecord
  include Ransackable

  belongs_to :order
  belongs_to :product, optional: true

  enum :item_type, { catalogue: 0, mystery_box: 1 }

  validates :name, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price, numericality: { greater_than_or_equal_to: 0 }

  def line_total
    quantity * unit_price.to_d
  end

  def to_s
    "#{quantity} × #{name}"
  end
end
