# Pieces a shopper has selected for this visit. Stored in the session until
# checkout turns them into an order. Stock is never reduced here.
class Cart
  Line = Struct.new(:product, :quantity) do
    def line_total
      product.selling_price.to_d * quantity
    end
  end

  def initialize(session)
    @session = session
    @session[:cart] ||= {}
  end

  def add(product)
    return false unless product&.available_for_sale?

    id = product.id.to_s
    data[id] = [ data[id].to_i + 1, product.stock_quantity ].min
    true
  end

  def remove(product)
    data.delete(product.id.to_s)
  end

  def include?(product)
    data[product.id.to_s].to_i.positive?
  end

  def count
    data.values.sum(&:to_i)
  end

  def empty?
    items.empty?
  end

  def items
    return [] if data.blank?

    products = Product.available.with_storefront_includes.where(id: data.keys).index_by { |product| product.id.to_s }

    data.keys.filter_map do |id|
      product = products[id]
      unless product
        data.delete(id)
        next
      end

      quantity = [ data[id].to_i, product.stock_quantity ].min
      quantity.positive? ? Line.new(product, quantity) : nil
    end
  end

  def subtotal
    items.sum(&:line_total)
  end

  def clear
    @session[:cart] = {}
  end

  private

  def data
    @session[:cart]
  end
end
