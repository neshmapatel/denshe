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
  has_many_attached :clips

  CLIP_CONTENT_TYPES = %w[video/mp4 video/quicktime video/webm].freeze
  CLIP_EXTENSIONS = %w[.mp4 .mov .webm].freeze
  MAX_CLIPS = 3
  MAX_CLIP_BYTES = 25.megabytes

  enum :status, { draft: 0, active: 1, archived: 2 }

  validates :name, presence: true
  validates :sku, uniqueness: { allow_blank: true }
  validates :selling_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :purchase_price, numericality: { greater_than_or_equal_to: 0 }
  validates :compare_at_price_aud, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :australian_price_when_visible
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

  # In-stock pieces a shopper can still select.
  scope :available, -> { active.in_stock }
  # Active catalogue for the shop grid — includes sold-out pieces so they stay visible.
  scope :catalogue, -> { active }
  scope :visible_in_australia, -> { where(visible_in_australia: true) }
  scope :offered_in_australia, -> { visible_in_australia.where("selling_price_aud > 0") }
  scope :bestsellers, -> { available.where(bestseller: true) }
  scope :with_storefront_includes, -> { includes(:category, images_attachments: :blob) }

  def self.search_columns
    %w[name sku slug]
  end

  def self.catalogue_for(market)
    market&.australia? ? catalogue.offered_in_australia : catalogue
  end

  def self.available_for(market)
    market&.australia? ? available.offered_in_australia : available
  end

  before_validation :copy_supplier_from_purchase
  before_validation :nilify_blank_sku
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
    on_sale_for?(Market.india)
  end

  def discount_percentage
    discount_percentage_for(Market.india)
  end

  # Australia only lists a piece the admin has explicitly offered, at the
  # Australian price they typed. A blank price keeps it in the India shop.
  def offered_in?(market)
    return true unless market&.australia?

    visible_in_australia? && selling_price_aud.to_d.positive?
  end

  def price_for(market)
    market&.australia? ? selling_price_aud : selling_price
  end

  def compare_at_for(market)
    market&.australia? ? compare_at_price_aud : compare_at_price
  end

  def on_sale_for?(market)
    compare = compare_at_for(market)
    selling = price_for(market)
    compare.present? && selling.present? && compare.to_d > selling.to_d
  end

  def discount_percentage_for(market)
    return unless on_sale_for?(market)

    (((compare_at_for(market) - price_for(market)) / compare_at_for(market)) * 100).round
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

  def primary_image
    return unless images.attached?

    images.find_by(id: primary_image_id) || images.first
  end

  # The storefront shows a photograph only when one has been marked primary.
  def display_image
    return if primary_image_id.blank?

    gallery_images.find { |attachment| attachment.id == primary_image_id }
  end

  def primary_image?(attachment)
    attachment.present? && primary_image&.id == attachment.id
  end

  def attach_clips!(uploads)
    files = Array(uploads).compact_blank
    return [] if files.empty?

    problems = []
    room = [ MAX_CLIPS - clips.attachments.size, 0 ].max
    accepted = []

    files.each do |file|
      unless self.class.acceptable_clip?(file)
        problems << "#{clip_label(file)} must be an MP4, MOV, or WebM clip under 25 MB."
        next
      end

      if accepted.size >= room
        problems << "A piece can have up to three clips."
        break
      end

      accepted << file
    end

    clips.attach(accepted.map { |file| clip_attachment(file) }) if accepted.any?
    problems.uniq
  end

  def self.acceptable_clip?(file)
    size = file.size.to_i
    return false unless size.positive? && size <= MAX_CLIP_BYTES

    type = file.content_type.to_s.split(";").first
    return true if CLIP_CONTENT_TYPES.include?(type)

    name = file.try(:original_filename).to_s.downcase
    type.in?([ "", "application/octet-stream" ]) && CLIP_EXTENSIONS.any? { |extension| name.end_with?(extension) }
  end

  def remove_clips!(ids)
    Array(ids).compact_blank.each do |id|
      clips.find_by(id: id)&.purge
    end
    clips.reset
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

  def clip_label(file)
    file.try(:original_filename).presence || "That clip"
  end

  def clip_attachment(file)
    io = file.respond_to?(:tempfile) ? file.tempfile : file
    io.rewind if io.respond_to?(:rewind)

    {
      io: io,
      filename: clip_label(file),
      content_type: clip_content_type(file)
    }
  end

  def clip_content_type(file)
    type = file.content_type.to_s.split(";").first
    return type if CLIP_CONTENT_TYPES.include?(type)

    case File.extname(clip_label(file)).downcase
    when ".mov" then "video/quicktime"
    when ".webm" then "video/webm"
    else "video/mp4"
    end
  end

  def sync_opening_purchase_quantity
    return if quantity_purchased.to_i.positive? || stock_quantity.to_i <= 0

    self.quantity_purchased = stock_quantity
  end

  def copy_supplier_from_purchase
    self.supplier ||= purchase&.supplier
  end

  # The unique index treats "" as a real value, so a second product left without
  # a SKU raises a database error instead of saving.
  def nilify_blank_sku
    self.sku = nil if sku.blank?
  end

  def australian_price_when_visible
    return unless visible_in_australia?
    return if selling_price_aud.to_d.positive?

    errors.add(:selling_price_aud, "must be set when the piece is visible in Australia")
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
