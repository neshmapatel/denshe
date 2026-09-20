class Product < ApplicationRecord
  include Ransackable
  include Sluggable

  attr_accessor :skip_stock_history

  belongs_to :category
  has_many :inventory_movements, dependent: :destroy
  has_many :order_items, dependent: :restrict_with_error
  has_many_attached :images

  enum :status, { draft: 0, active: 1, archived: 2 }

  validates :name, presence: true
  validates :sku, uniqueness: { allow_blank: true }
  validates :selling_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :purchase_price, numericality: { greater_than_or_equal_to: 0 }
  validates :packaging_allocation, :shipping_allocation, numericality: { greater_than_or_equal_to: 0 }
  validates :stock_quantity, :quantity_purchased, :low_stock_threshold,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :published, -> { active }
  scope :featured_on_home, -> { active.where(featured: true).order(updated_at: :desc) }
  scope :new_arrivals, -> { active.where(new_arrival: true).order(created_at: :desc) }
  scope :low_stock, -> { where("stock_quantity > 0 AND stock_quantity <= low_stock_threshold") }
  scope :out_of_stock, -> { where("stock_quantity <= 0") }

  before_create :sync_opening_purchase_quantity
  after_create :log_opening_stock_movement
  after_update :log_direct_stock_edit

  def to_s
    name
  end

  def available_for_sale?
    active? && stock_quantity.positive?
  end

  def low_stock?
    stock_quantity.positive? && stock_quantity <= low_stock_threshold
  end

  def out_of_stock?
    stock_quantity <= 0
  end

  def sold_quantity
    inventory_movements.where(movement_type: :customer_order).sum("ABS(quantity)")
  end

  def contribution_margin
    selling_price.to_d - purchase_price.to_d - packaging_allocation.to_d - shipping_allocation.to_d
  end

  def adjust_stock!(quantity:, movement_type:, reason:, admin_user: nil, order: nil)
    quantity = quantity.to_i
    raise ArgumentError, "Quantity cannot be zero" if quantity.zero?

    with_lock do
      new_quantity = stock_quantity + quantity
      raise ArgumentError, "Stock cannot be negative" if new_quantity.negative?

      inventory_movements.create!(
        quantity: quantity,
        movement_type: movement_type,
        reason: reason,
        admin_user: admin_user,
        order: order
      )

      attrs = { stock_quantity: new_quantity }
      if movement_type.to_sym == :purchase && quantity.positive?
        attrs[:quantity_purchased] = quantity_purchased + quantity
      end

      self.skip_stock_history = true
      begin
        update!(attrs)
      ensure
        self.skip_stock_history = false
      end
    end
  end

  private

  def sync_opening_purchase_quantity
    return if quantity_purchased.to_i.positive? || stock_quantity.to_i <= 0

    self.quantity_purchased = stock_quantity
  end

  def log_opening_stock_movement
    return if stock_quantity.to_i.zero?

    inventory_movements.create!(
      quantity: stock_quantity,
      movement_type: :purchase,
      reason: "Opening stock"
    )
  end

  def log_direct_stock_edit
    return if skip_stock_history
    return unless saved_change_to_stock_quantity?

    previous_quantity, current_quantity = saved_change_to_stock_quantity
    delta = current_quantity - previous_quantity
    return if delta.zero?

    inventory_movements.create!(
      quantity: delta,
      movement_type: :adjustment,
      reason: "Admin product edit"
    )
  end
end
