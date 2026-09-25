# Turns storefront query parameters into a product relation, plus the facet
# metadata the shop sidebar needs to render itself.
class ProductFilter
  SORTS = {
    "curated" => "Curated",
    "newest" => "New in",
    "price-asc" => "Price: low to high",
    "price-desc" => "Price: high to low",
    "name" => "A to Z"
  }.freeze

  DEFAULT_SORT = "curated"

  # Upper bounds are exclusive so the bands never overlap.
  PRICE_BANDS = [
    { id: "under-249", label: "Under ₹249", min: nil, max: 249 },
    { id: "249-499", label: "₹249 to ₹499", min: 249, max: 499 },
    { id: "499-999", label: "₹499 to ₹999", min: 499, max: 999 },
    { id: "999-plus", label: "₹999 and above", min: 999, max: nil }
  ].freeze

  FACETS = %i[material colour price].freeze

  attr_reader :query, :material, :colour, :price, :sort

  def initialize(params, scope: Product.available)
    @base = scope
    @query = params[:q].to_s.strip.presence
    @material = params[:material].presence
    @colour = params[:colour].presence
    @price = params[:price].presence_in(PRICE_BANDS.map { |band| band[:id] })
    @sort = params[:sort].presence_in(SORTS.keys) || DEFAULT_SORT
  end

  def results
    @results ||= order(apply_all(@base))
  end

  def filtering?
    [ query, material, colour, price ].any?(&:present?)
  end

  # Each facet counts against the other active filters but not against itself,
  # so refining one facet never empties the options of another.
  def material_options
    @material_options ||= options_for(:material)
  end

  def colour_options
    @colour_options ||= options_for(:colour)
  end

  def price_options
    @price_options ||= begin
      counts = apply_all(@base, except: :price)
      PRICE_BANDS.filter_map do |band|
        count = within_band(counts, band).count
        { value: band[:id], label: band[:label], count: count } if count.positive?
      end
    end
  end

  # Chips shown above the grid, each carrying the params needed to remove it.
  def applied
    chips = []
    chips << { label: "“#{query}”", param: :q } if query
    chips << { label: material, param: :material } if material
    chips << { label: colour.to_s.titleize, param: :colour } if colour
    if price && (band = PRICE_BANDS.find { |candidate| candidate[:id] == price })
      chips << { label: band[:label], param: :price }
    end
    chips
  end

  private

  def options_for(column)
    apply_all(@base, except: column)
      .where.not(column => [ nil, "" ])
      .group(column)
      .order(Arel.sql("COUNT(*) DESC"))
      .count
      .map { |value, count| { value: value, label: value.to_s.titleize, count: count } }
  end

  def apply_all(relation, except: nil)
    relation = search(relation) if query && except != :q
    relation = relation.where(material: material) if material && except != :material
    relation = relation.where(colour: colour) if colour && except != :colour

    if price && except != :price && (band = PRICE_BANDS.find { |candidate| candidate[:id] == price })
      relation = within_band(relation, band)
    end

    relation
  end

  def within_band(relation, band)
    relation = relation.where(selling_price: band[:min]..) if band[:min]
    relation = relation.where(selling_price: ...band[:max]) if band[:max]
    relation
  end

  def search(relation)
    pattern = "%#{Product.sanitize_sql_like(query)}%"

    relation.left_joins(:category).where(
      "products.name ILIKE :q OR products.short_description ILIKE :q OR " \
      "products.material ILIKE :q OR products.colour ILIKE :q OR categories.name ILIKE :q",
      q: pattern
    )
  end

  def order(relation)
    case sort
    when "newest" then relation.order(created_at: :desc, id: :desc)
    when "price-asc" then relation.order(selling_price: :asc, name: :asc)
    when "price-desc" then relation.order(selling_price: :desc, name: :asc)
    when "name" then relation.order(name: :asc)
    else
      relation.order(
        Arel.sql("products.featured DESC, products.bestseller DESC, products.new_arrival DESC"),
        created_at: :desc
      )
    end
  end
end
