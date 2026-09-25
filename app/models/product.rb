class Product < ApplicationRecord
  include Ransackable
  include Searchable
  include Sluggable

  attr_accessor :skip_stock_history, :opening_stock_reason

  belongs_to :category
  belongs_to :supplier, optional: true
  belongs_to :purchase, optional: true
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
  scope :in_stock, -> { where("stock_quantity > 0") }
  scope :out_of_stock, -> { where("stock_quantity <= 0") }
  scope :earrings, -> { joins(:category).where(categories: { slug: "earrings" }) }

  # Everything the storefront is allowed to list. Draft and archived pieces, and
  # anything already sold, stay out of the customer catalogue.
  scope :available, -> { active.in_stock }
  scope :bestsellers, -> { available.where(bestseller: true) }
  scope :with_storefront_includes, -> { includes(:category, images_attachments: :blob) }

  def self.search_columns
    %w[name sku slug]
  end

  before_validation :copy_supplier_from_purchase
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

  # Most of the catalogue is bought a single piece at a time, so a stock of one
  # is a genuine "there is only this one" rather than a low-stock warning.
  def one_of_one?
    stock_quantity == 1
  end

  def on_sale?
    compare_at_price.present? && compare_at_price > selling_price
  end

  def discount_percentage
    return unless on_sale?

    (((compare_at_price - selling_price) / compare_at_price) * 100).round
  end

  # Primary image first, then the rest, so galleries and cards agree on order.
  def gallery_images
    return ActiveStorage::Attachment.none unless images.attached?

    attachments = images.to_a
    primary = attachments.find { |attachment| attachment.id == primary_image_id }
    primary ? [ primary, *(attachments - [ primary ]) ] : attachments
  end

  def hover_image
    gallery_images[1]
  end

  def contribution_margin
    selling_price.to_d - purchase_price.to_d - packaging_allocation.to_d - shipping_allocation.to_d
  end

  # Read from the loaded attachments so an admin list with `with_attached_images`
  # does not fire a query per row.
  def primary_image
    attachments = images.attachments
    return if attachments.blank?

    attachments.find { |attachment| attachment.id == primary_image_id } || attachments.first
  end

  # The storefront shows a photograph only when one has been marked primary.
  def display_image
    return if primary_image_id.blank?

    gallery_images.find { |attachment| attachment.id == primary_image_id }
  end

  def primary_image?(attachment)
    attachment.present? && primary_image&.id == attachment.id
  end

  def remove_images!(ids)
    Array(ids).compact_blank.each do |id|
      images.find_by(id: id)&.purge
    end
    images.reset
  end

  def set_primary_image!(attachment_or_id)
    return if attachment_or_id.blank?

    id = attachment_or_id.respond_to?(:id) ? attachment_or_id.id : attachment_or_id.to_i
    return unless images.exists?(id: id)

    update_column(:primary_image_id, id)
  end

  def ensure_primary_image!
    if images.attached?
      return if primary_image_id.present? && images.exists?(id: primary_image_id)

      update_column(:primary_image_id, images.first.id)
    elsif primary_image_id.present?
      update_column(:primary_image_id, nil)
    end
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

  def copy_supplier_from_purchase
    self.supplier ||= purchase&.supplier
  end

  def log_opening_stock_movement
    return if stock_quantity.to_i.zero?
    return if skip_stock_history

    inventory_movements.create!(
      quantity: stock_quantity,
      movement_type: :purchase,
      reason: opening_stock_reason.presence || "Opening stock"
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
