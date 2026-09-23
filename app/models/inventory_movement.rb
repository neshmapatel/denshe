class InventoryMovement < ApplicationRecord
  include Ransackable
  include Searchable

  belongs_to :product
  belongs_to :admin_user, optional: true
  belongs_to :order, optional: true

  enum :movement_type, {
    purchase: 0,
    customer_order: 1,
    adjustment: 2,
    damaged: 3,
    exhibition: 4,
    return_to_stock: 5,
    other: 6
  }

  validates :quantity, numericality: { other_than: 0, only_integer: true }
  validates :movement_type, presence: true

  scope :newest_first, -> { order(created_at: :desc) }

  def self.search_columns
    %w[reason products.name products.sku products.slug]
  end

  def self.search_joins
    [ :product ]
  end

  def to_s
    signed = quantity.positive? ? "+#{quantity}" : quantity.to_s
    "#{signed} · #{movement_type.humanize} · #{product.name}"
  end
end
