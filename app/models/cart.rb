# Pieces a shopper has selected for this visit. The session remembers the
# selection, and a CartHold records it so other shoppers can see what is left.
# Stock is never reduced here.
class Cart
  Line = Struct.new(:product, :quantity, :market) do
    def line_total
      product.price_for(market).to_d * quantity
    end

    def offered?
      product.offered_in?(market)
    end
  end

  def initialize(session, market: Market.india)
    @session = session
    @market = market || Market.india
    @session[:cart] ||= {}
    refresh_holds
  end

  def session_key
    @session[:cart_key] ||= SecureRandom.uuid
  end

  # :added, :held (another cart already has the remaining pieces), or :unavailable.
  def add(product)
    return :unavailable unless product&.available_for_sale?
    return :not_offered unless product.offered_in?(@market)

    Product.transaction do
      locked = Product.lock.find(product.id)
      return :unavailable unless locked.available_for_sale?

      CartHold.release_stale!
      others = CartHold.fresh.where(product_id: locked.id).where.not(session_key: session_key).sum(:quantity)
      current = quantity_of(locked)
      return others.positive? ? :held : :unavailable if locked.stock_quantity - others <= current

      next_quantity = current + 1
      persist_hold(locked.id, next_quantity)
      data[locked.id.to_s] = next_quantity
    end

    :added
  end

  def remove(product)
    data.delete(product.id.to_s)
    CartHold.where(session_key: session_key, product_id: product.id).delete_all if @session[:cart_key]
  end

  def include?(product)
    quantity_of(product).positive?
  end

  def quantity_of(product)
    data[product.id.to_s].to_i
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
    others = CartHold.fresh.where(product_id: products.values.map(&:id)).where.not(session_key: session_key).group(:product_id).sum(:quantity)
    changed = data.keys.any? { |id| products[id].nil? }

    lines = data.keys.filter_map do |id|
      product = products[id]
      unless product
        data.delete(id)
        next
      end

      room = product.stock_quantity - others[product.id].to_i
      quantity = [ data[id].to_i, room ].min
      if quantity != data[id].to_i
        changed = true
        quantity.positive? ? data[id] = quantity : data.delete(id)
      end
      quantity.positive? ? Line.new(product, quantity, @market) : nil
    end

    sync_holds! if changed
    lines
  end

  def subtotal
    checkout_items.sum(&:line_total)
  end

  # Lines that can be bought in the shop the visitor is browsing.
  def checkout_items
    items.select(&:offered?)
  end

  def clear
    CartHold.where(session_key: @session[:cart_key]).delete_all if @session[:cart_key]
    @session[:cart] = {}
  end

  private

  def data
    @session[:cart]
  end

  def refresh_holds
    return if data.blank?

    CartHold.release_stale!
    if @session[:cart_key].blank?
      data.each { |id, quantity| persist_hold(id, quantity.to_i) if quantity.to_i.positive? }
      return
    end

    live_ids = CartHold.where(session_key: session_key).pluck(:product_id).map(&:to_s)
    (data.keys - live_ids).each { |id| data.delete(id) }
    return if data.blank?

    CartHold.where(session_key: session_key, product_id: data.keys).update_all(updated_at: Time.current)
  end

  def persist_hold(product_id, quantity)
    hold = CartHold.find_or_initialize_by(session_key: session_key, product_id: product_id)
    hold.quantity = quantity
    hold.updated_at = Time.current
    hold.save!
  end

  def sync_holds!
    kept = data.select { |_id, quantity| quantity.to_i.positive? }
    scope = CartHold.where(session_key: session_key)
    scope.where.not(product_id: kept.keys).delete_all
    kept.each { |id, quantity| persist_hold(id, quantity) }
  end
end