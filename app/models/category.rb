class Category < ApplicationRecord
  include Ransackable
  include Searchable
  include Sluggable

  has_many :products, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :slug_not_reserved_for_collection_line

  scope :ordered, -> { order(:position, :name) }
  scope :stocked, -> { where(id: Product.catalogue.select(:category_id)) }

  def available_products
    products.available
  end

  def catalogue_products
    products.catalogue
  end

  # Collection tiles borrow the strongest piece in the collection as their cover.
  def cover_product(market = Market.india)
    @cover_products ||= {}
    @cover_products[market.code] ||= products.merge(Product.catalogue_for(market))
      .where.not(primary_image_id: nil)
      .order(Arel.sql("CASE WHEN products.stock_quantity > 0 THEN 0 ELSE 1 END"),
             featured: :desc, bestseller: :desc, created_at: :desc)
      .first
  end

  def self.search_columns
    %w[name slug]
  end

  def to_s
    name
  end

  private

  def slug_not_reserved_for_collection_line
    return unless CollectionLine.reserved_slug?(slug)

    errors.add(:slug, "is reserved for the #{slug} collection line")
  end
end
