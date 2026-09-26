# Stand-in selling prices and photographs for development.
#
# The intake seeds record the real purchase price and leave selling price at 0
# and status as draft, so the shop renders as an empty catalogue. This fills
# only those gaps, and only in development. A piece that already has a selling
# price or a photograph is left alone, and purchase prices are never changed.

return unless Rails.env.development?

require "zlib"

module LocalShowcase
  WIDTH = 480
  HEIGHT = 640
  IVORY = [ 244, 239, 230 ].freeze
  NAVY = [ 16, 16, 72 ].freeze

  ACCENTS = {
    "Earrings" => [ 184, 146, 74 ],
    "Rings" => [ 122, 92, 46 ],
    "Bracelets" => [ 32, 32, 144 ],
    "Sets" => [ 90, 70, 110 ],
    "Kadas" => [ 140, 110, 50 ],
    "Handchains" => [ 24, 24, 90 ],
    "Chain Pendants" => [ 160, 120, 60 ],
    "Combo" => [ 70, 80, 90 ]
  }.freeze
  DEFAULT_ACCENT = [ 96, 86, 74 ].freeze

  module_function

  def fill!
    priced = 0
    pictured = 0

    Product.includes(:category).find_each do |product|
      priced += 1 if assign_price!(product)
      pictured += 1 if assign_images!(product)
    end

    puts "local showcase: priced=#{priced} pictured=#{pictured}"
  end

  def assign_price!(product)
    return false unless product.selling_price.to_d.zero?

    selling = retail_price(product.purchase_price)
    attrs = { selling_price: selling, status: :active }
    attrs[:compare_at_price] = selling + 300 if product.compare_at_price.blank? && (product.id % 6).zero?
    product.update!(attrs)
    restock!(product) if product.stock_quantity.zero?
    true
  end

  # About twelve times the purchase price, snapped to the ₹x49 / ₹x99 rhythm
  # the shop's price filters are built around.
  def retail_price(purchase)
    raw = [ purchase.to_d * 12, 200 ].max
    snapped = ((raw / 50.0).ceil * 50) - 1
    snapped.clamp(199, 2499)
  end

  def restock!(product)
    product.adjust_stock!(quantity: 1, movement_type: :adjustment, reason: "Local showcase")
  end

  def assign_images!(product)
    if product.images.attached?
      product.ensure_primary_image!
      return false
    end

    accent = ACCENTS[product.category.name] || DEFAULT_ACCENT
    attach(product, card(accent, hole: false), "front")
    attach(product, card(accent, hole: true), "detail")
    product.ensure_primary_image!
    true
  end

  def attach(product, bytes, label)
    product.images.attach(
      io: StringIO.new(bytes),
      filename: "local-showcase-#{product.id}-#{label}.png",
      content_type: "image/png"
    )
  end

  def card(accent, hole:)
    rows = Array.new(HEIGHT) { ivory_row }
    draw_disc(rows, 240, 300, 168, accent)
    draw_disc(rows, 240, 300, 78, IVORY) if hole
    draw_disc(rows, 240, 300, 18, NAVY)
    encode_png(rows)
  end

  def ivory_row
    ("\x00".b + (IVORY.pack("C*") * WIDTH)).b
  end

  def draw_disc(rows, cx, cy, radius, rgb)
    packed = rgb.pack("C*")
    radius.downto(-radius) do |dy|
      y = cy + dy
      next unless y.between?(0, HEIGHT - 1)

      span = Math.sqrt(radius * radius - dy * dy).floor
      x0 = [ cx - span, 0 ].max
      x1 = [ cx + span, WIDTH - 1 ].min
      offset = 1 + (x0 * 3)
      rows[y][offset, (x1 - x0 + 1) * 3] = packed * (x1 - x0 + 1)
    end
  end

  def encode_png(rows)
    raw = rows.join
    signature = (+"\x89PNG\r\n\x1a\n").b
    ihdr = [ WIDTH, HEIGHT, 8, 2, 0, 0, 0 ].pack("NNCCCCC")
    signature + chunk("IHDR", ihdr) + chunk("IDAT", Zlib::Deflate.deflate(raw)) + chunk("IEND", "")
  end

  def chunk(type, data)
    type = type.b
    data = data.b
    [ data.bytesize ].pack("N") + type + data + [ Zlib.crc32(type + data) ].pack("N")
  end
end

LocalShowcase.fill!
