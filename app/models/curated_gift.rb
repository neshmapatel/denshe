class CuratedGift < ApplicationRecord
  include Ransackable
  include Searchable
  include Sluggable
  include WebpImages

  has_many :order_items, dependent: :nullify

  enum :status, { draft: 0, active: 1, archived: 2 }, default: :active

  validates :name, presence: true
  validates :product_title, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :compare_at_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :discount_percent, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position, :id) }
  scope :published, -> { active.ordered }

  before_validation :sync_discounted_prices

  def self.search_columns
    %w[name product_title subtitle slug description]
  end

  def to_s
    product_title.presence || name
  end

  def title
    product_title.presence || name
  end

  def display_image
    images.first
  end

  def on_sale?
    compare_at_price.present? && price.present? && compare_at_price.to_d > price.to_d
  end

  def discount_label
    return "—" if discount_percent.to_d.zero?

    text = format("%.2f", discount_percent.to_d).sub(/0+\z/, "").sub(/\.\z/, "")
    "#{text}%"
  end

  def sync_discounted_prices
    marked = compare_at_price.to_d
    selling = price.to_d

    if marked.positive? && selling.positive? && marked > selling
      self.discount_percent = (((marked - selling) / marked) * 100).round(2)
    elsif marked.positive? && discount_percent.to_d.positive? && selling.zero?
      self.price = (marked * (100 - discount_percent.to_d) / 100).round(2)
    end
  end

  DEFAULTS = [
    {
      slug: "little-finds",
      name: "Treasure Drop — Little Finds",
      product_title: "Little Finds | Mystery Jewellery | ₹499",
      subtitle: "Little Finds",
      price: 499,
      description: "For a fun, accessible introduction to DeNshe's mystery jewellery.",
      position: 1,
      image_filename: "little-finds.jpg"
    },
    {
      slug: "the-charm-edit",
      name: "Treasure Drop — The Charm Edit",
      product_title: "The Charm Edit | Mystery Jewellery | ₹699",
      subtitle: "The Charm Edit",
      price: 699,
      description: "A little more to discover, with wearable jewellery selected for everyday styling.",
      position: 2,
      image_filename: "the-charm-edit.jpg"
    },
    {
      slug: "the-statement-edit",
      name: "Treasure Drop — The Statement Edit",
      product_title: "The Statement Edit | Mystery Jewellery | ₹899",
      subtitle: "The Statement Edit",
      price: 899,
      description: "For customers who want a more expressive mix of jewellery and statement pieces.",
      position: 3,
      image_filename: "the-statement-edit.jpg"
    },
    {
      slug: "the-signature-edit",
      name: "Treasure Drop — The Signature Edit",
      product_title: "The Signature Edit | Anti-Tarnish Neckpieces & Bracelets | ₹1,999",
      subtitle: "The Signature Edit",
      price: 1999,
      description: "Curated modern everyday jewellery featuring anti-tarnish neckpieces, delicate chains, and sleek bracelets designed for effortless daily styling.",
      position: 4,
      image_filename: "the-signature-edit.jpg"
    },
    {
      slug: "the-muse-edit",
      name: "Treasure Drop — The Muse Edit",
      product_title: "The Muse Edit | Indian Jhumkas & Modern Korean Jewellery | ₹2,799",
      subtitle: "Fusion edit — Indian & modern",
      price: 2799,
      description: "Our ultimate luxury curation blending rich Indian traditional jhumkas with chic modern Korean earrings and contemporary anti-tarnish accents. An expressive, elevated mix of artisanal heritage and trendy daily styling.",
      position: 5,
      image_filename: "the-muse-edit.jpg"
    }
  ].freeze

  def self.seed_defaults!(force_reimage: false)
    DEFAULTS.each do |attrs|
      gift = find_by(slug: attrs[:slug])
      if gift.nil? && attrs[:slug] == "the-signature-edit"
        gift = find_by(slug: "noor")
      end
      gift ||= new(slug: attrs[:slug])

      gift.slug = attrs[:slug]
      gift.name = attrs[:name]
      gift.product_title = attrs[:product_title]
      gift.subtitle = attrs[:subtitle]
      gift.price = attrs[:price]
      gift.description = attrs[:description]
      gift.position = attrs[:position]
      gift.status = :active
      gift.save!

      if attrs[:image_filename].present?
        image_path = Rails.root.join("app/assets/images/curated_gifts", attrs[:image_filename])
        if File.exist?(image_path)
          current_filename = gift.images.first&.filename&.to_s
          needs_image = !gift.images.attached? || force_reimage || (current_filename != attrs[:image_filename])
          if needs_image
            gift.images.purge if gift.images.attached?
            gift.images.attach(
              io: File.open(image_path),
              filename: attrs[:image_filename],
              content_type: "image/jpeg"
            )
          end
        end
      end
    end
  end
end
