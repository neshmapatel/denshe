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

  ComboLine = Struct.new(:token, :combo, :products, :market) do
    def line_total
      combo.price.to_d
    end

    def offered?
      !market&.australia?
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
      return :held if combo_product_ids.include?(locked.id)
      return others.positive? ? :held : :unavailable if locked.stock_quantity - others <= current

      next_quantity = current + 1
      persist_hold(locked.id, next_quantity)
      data[locked.id.to_s] = next_quantity
    end

    :added
  end

  def remove(product)
    return if product.nil?

    data.delete(product.id.to_s)
    drop_combos_containing(product.id)
    CartHold.where(session_key: session_key, product_id: product.id).delete_all if @session[:cart_key]
    @combo_lines = nil
  end

  # :added, :incomplete, :held, :unavailable, or :not_offered.
  # The combo is charged at the admin price. Each chosen piece is held so it
  # cannot also be selected on its own.
  def add_combo(combo, picks)
    return :not_offered if @market.australia?
    return :unavailable unless combo&.active?

    groups = combo.groups.includes(:options).to_a
    return :unavailable if groups.empty?

    chosen_ids = []
    groups.each do |group|
      raw = picks[group.id.to_s] || picks[group.id] || picks[group.id.to_s.to_sym]
      ids = Array(raw).map(&:to_i).reject(&:zero?).uniq
      allowed = group.options.map(&:product_id)
      return :incomplete unless ids.size == group.choose_count && (ids - allowed).empty?

      chosen_ids.concat(ids)
    end
    return :incomplete if chosen_ids.uniq.size != chosen_ids.size
    return :held if chosen_ids.any? { |id| data[id.to_s].to_i.positive? || combo_product_ids.include?(id) }

    Product.transaction do
      locked = Product.lock.where(id: chosen_ids).index_by(&:id)
      return :unavailable unless chosen_ids.all? { |id| locked[id]&.available_for_sale? }

      CartHold.release_stale!
      others = CartHold.fresh.where(product_id: chosen_ids).where.not(session_key: session_key).group(:product_id).sum(:quantity)
      return :held if chosen_ids.any? { |id| locked[id].stock_quantity - others[id].to_i < 1 }

      chosen_ids.each { |id| persist_hold(id, 1) }
      combo_data[SecureRandom.hex(4)] = { "combo_id" => combo.id, "product_ids" => chosen_ids }
      @combo_lines = nil
    end

    :added
  end

  def remove_combo(token)
    entry = combo_data.delete(token.to_s)
    return unless entry

    Array(entry["product_ids"]).each do |id|
      next if data[id.to_s].to_i.positive?

      CartHold.where(session_key: session_key, product_id: id).delete_all if @session[:cart_key]
    end
    @combo_lines = nil
  end

  def include?(product)
    quantity_of(product).positive?
  end

  def quantity_of(product)
    data[product.id.to_s].to_i
  end

  def holding?(product)
    include?(product) || combo_product_ids.include?(product.id)
  end

  def combo_product_ids
    combo_data.values.flat_map { |entry| Array(entry["product_ids"]).map(&:to_i) }.uniq
  end

  def count
    data.values.sum(&:to_i) + combo_data.size
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

  def combo_lines
    return @combo_lines unless @combo_lines.nil?
    return @combo_lines = [] if combo_data.blank?

    combos = Combo.active.where(id: combo_data.values.map { |entry| entry["combo_id"] })
      .includes(groups: :products)
      .index_by(&:id)
    lines = []
    combo_data.each do |token, entry|
      combo = combos[entry["combo_id"].to_i]
      wanted = Array(entry["product_ids"]).map(&:to_i)
      chosen = wanted.filter_map { |id| combo && products_by_id(combo)[id] }
      if combo.nil? || chosen.size != wanted.size || chosen.any? { |product| !product.available_for_sale? }
        release_combo_entry(entry)
        combo_data.delete(token)
        next
      end

      lines << ComboLine.new(token, combo, chosen, @market)
    end
    @combo_lines = lines
  end

  def subtotal
    checkout_items.sum(&:line_total) + combo_lines.select(&:offered?).sum(&:line_total)
  end

  # Lines that can be bought in the shop the visitor is browsing.
  def checkout_items
    items.select(&:offered?)
  end

  def clear
    CartHold.where(session_key: @session[:cart_key]).delete_all if @session[:cart_key]
    @session[:cart] = {}
    @session[:cart_combos] = {}
    @combo_lines = nil
  end

  def combo_data
    @session[:cart_combos] ||= {}
  end

  private

  def data
    @session[:cart]
  end

  def refresh_holds
    return if data.blank? && combo_data.blank?

    CartHold.release_stale!
    refresh_piece_holds
    refresh_combo_holds
  end

  def refresh_piece_holds
    return if data.blank?

    if @session[:cart_key].blank?
      data.each { |id, quantity| persist_hold(id, quantity.to_i) if quantity.to_i.positive? }
      return
    end

    live_ids = CartHold.where(session_key: session_key).pluck(:product_id).map(&:to_s)
    (data.keys - live_ids).each { |id| data.delete(id) }
    return if data.blank?

    CartHold.where(session_key: session_key, product_id: data.keys).update_all(updated_at: Time.current)
  end

  def refresh_combo_holds
    return if combo_data.blank?

    live_ids = CartHold.where(session_key: session_key).pluck(:product_id)
    combo_data.delete_if do |_token, entry|
      (Array(entry["product_ids"]).map(&:to_i) - live_ids).any?
    end
    ids = combo_product_ids
    return if ids.empty?

    CartHold.where(session_key: session_key, product_id: ids).update_all(updated_at: Time.current)
  end

  def persist_hold(product_id, quantity)
    hold = CartHold.find_or_initialize_by(session_key: session_key, product_id: product_id)
    hold.quantity = quantity
    hold.updated_at = Time.current
    hold.save!
  end

  def sync_holds!
    kept = data.select { |_id, quantity| quantity.to_i.positive? }
    extra = combo_product_ids
    scope = CartHold.where(session_key: session_key)
    scope.where.not(product_id: kept.keys.map(&:to_i) + extra).delete_all
    kept.each { |id, quantity| persist_hold(id, quantity) }
    (extra - kept.keys.map(&:to_i)).each { |id| persist_hold(id, 1) }
  end

  def drop_combos_containing(product_id)
    combo_data.delete_if do |_token, entry|
      Array(entry["product_ids"]).map(&:to_i).include?(product_id.to_i)
    end
  end

  def release_combo_entry(entry)
    return unless @session[:cart_key]

    Array(entry["product_ids"]).each do |id|
      next if data[id.to_s].to_i.positive?

      CartHold.where(session_key: session_key, product_id: id).delete_all
    end
  end

  def products_by_id(combo)
    combo.groups.flat_map(&:products).index_by(&:id)
  end
end