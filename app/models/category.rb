class Category < ApplicationRecord
  include Ransackable
  include Searchable
  include Sluggable

  has_many :products, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position, :name) }
  scope :stocked, -> { where(id: Product.available.select(:category_id)) }

  def available_products
    products.available
  end

  # Collection tiles borrow the strongest piece in the collection as their cover.
  def cover_product
    @cover_product ||= available_products
      .where.not(primary_image_id: nil)
      .order(featured: :desc, bestseller: :desc, created_at: :desc)
      .first
  end

  def self.search_columns
    %w[name slug]
  end

  def to_s
    name
  end
end
