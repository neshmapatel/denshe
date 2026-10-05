# Two shop lines share the same type shelves (earrings, rings, …).
# Western is everyday wear; Indian is the festive cabinet.
class CollectionLine
  SLUGS = %w[western indian].freeze

  def self.all
    SLUGS.map { |slug| new(slug) }
  end

  def self.find(slug)
    return unless SLUGS.include?(slug.to_s)

    new(slug.to_s)
  end

  def self.reserved_slug?(slug)
    SLUGS.include?(slug.to_s)
  end

  def initialize(slug)
    @slug = slug.to_s
  end

  attr_reader :slug

  def key
    @slug.to_sym
  end

  def western?
    @slug == "western"
  end

  def indian?
    @slug == "indian"
  end

  def name
    western? ? "Western Collection" : "Indian Collection"
  end

  def short_name
    western? ? "Western" : "Indian"
  end

  def tagline
    if western?
      "Everyday pieces for the hours in between."
    else
      "Festive jewellery for celebrations and seasons."
    end
  end

  def ==(other)
    other.is_a?(self.class) && other.slug == slug
  end
end
