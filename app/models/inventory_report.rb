class InventoryReport
  FILTER_KEYS = %w[category_id supplier_id min_price max_price].freeze

  attr_reader :filters

  def initialize(filters = {})
    raw = filters.respond_to?(:to_unsafe_h) ? filters.to_unsafe_h : filters.to_h
    @filters = raw.with_indifferent_access.slice(*FILTER_KEYS)
  end

  def products
    @products ||= filtered_scope.includes(:category, :supplier).order("categories.position", "categories.name", "products.name")
  end

  def category_summaries
    filtered_scope
      .group("categories.id", "categories.name", "categories.position")
      .order("categories.position", "categories.name")
      .pluck(
        Arel.sql("categories.id"),
        Arel.sql("categories.name"),
        Arel.sql("COUNT(products.id)"),
        Arel.sql("COALESCE(SUM(products.stock_quantity), 0)"),
        Arel.sql("COALESCE(SUM(products.purchase_price * products.quantity_purchased), 0)")
      )
      .map do |id, name, designs, pieces, spend|
        {
          category_id: id,
          name: name,
          designs: designs.to_i,
          pieces: pieces.to_i,
          purchase_total: spend.to_d
        }
      end
  end

  def totals
    {
      designs: filtered_scope.count,
      pieces: filtered_scope.sum(:stock_quantity),
      purchase_total: filtered_scope.sum(Arel.sql("products.purchase_price * products.quantity_purchased"))
    }
  end

  def selected_category
    Category.find_by(id: category_id) if category_id
  end

  def selected_supplier
    Supplier.find_by(id: supplier_id) if supplier_id
  end

  def category_id
    integer_filter(:category_id)
  end

  def supplier_id
    integer_filter(:supplier_id)
  end

  def min_price
    decimal_filter(:min_price)
  end

  def max_price
    decimal_filter(:max_price)
  end

  def summary_title
    parts = [ "Totals" ]
    parts << selected_category.name if selected_category
    parts << selected_supplier.name if selected_supplier
    if min_price || max_price
      min = min_price ? "₹#{min_price}" : "any"
      max = max_price ? "₹#{max_price}" : "any"
      parts << "purchase #{min}–#{max}"
    end
    parts.join(" · ")
  end

  def filter_params
    {
      category_id: category_id,
      supplier_id: supplier_id,
      min_price: min_price,
      max_price: max_price
    }.compact
  end

  private

  def filtered_scope
    scope = Product.joins(:category)
    scope = scope.where(category_id: category_id) if category_id
    scope = scope.where(supplier_id: supplier_id) if supplier_id
    scope = scope.where("products.purchase_price >= ?", min_price) if min_price
    scope = scope.where("products.purchase_price <= ?", max_price) if max_price
    scope
  end

  def integer_filter(key)
    value = filters[key].presence
    Integer(value, exception: false)
  end

  def decimal_filter(key)
    value = filters[key].to_s.strip
    return if value.blank?

    BigDecimal(value)
  rescue ArgumentError
    nil
  end
end
