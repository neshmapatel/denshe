module StorefrontHelper
  # Width/height caps per slot. Portrait crops suit jewellery photography.
  IMAGE_SIZES = {
    thumb: [ 200, 267 ],
    card: [ 700, 933 ],
    feature: [ 1100, 1467 ],
    stage: [ 1400, 1867 ]
  }.freeze

  # The catalogue grid is about 200px wide, so a 420px WebP covers a sharp
  # screen without sending the 700px shop photo a hundred times.
  CATALOGUE_IMAGE = [ 420, 560 ].freeze

  # Lifestyle art that stands in for a product photo on a collection tile.
  COLLECTION_COVERS = {
    "bracelets" => "collection-bracelets.jpg",
    "earrings" => "collection-earrings.jpg",
    "chain-pendants" => "collection-chain-pendants.jpg"
  }.freeze

  # Active Storage prefers libvips. When that library is missing, the
  # initializer switches to ImageMagick. If neither can load, keep the
  # original file instead of serving a broken image.
  def self.variants_supported?
    return @variants_supported unless @variants_supported.nil?

    @variants_supported = begin
      require "image_processing/#{ActiveStorage.variant_processor}"
      true
    rescue LoadError, StandardError
      false
    end
  end

  def collection_cover(category)
    COLLECTION_COVERS[category.slug]
  end

  def piece_image(attachment, size: :card, **options)
    return if attachment.blank?

    image_tag piece_image_source(attachment, size),
              loading: options.delete(:loading) || "lazy",
              decoding: "async",
              **options
  end

  def piece_image_source(attachment, size)
    image_variant(attachment, resize_to_limit: IMAGE_SIZES.fetch(size), quality: 82)
  end

  def catalogue_image_source(attachment)
    image_variant(attachment, resize_to_limit: CATALOGUE_IMAGE, format: :jpeg, quality: 70)
  end

  def image_variant(attachment, quality:, **transformations)
    return attachment unless StorefrontHelper.variants_supported? && attachment.variable?

    # libvips takes quality inside saver. ImageMagick takes it as its own step.
    if ActiveStorage.variant_processor == :mini_magick
      transformations[:quality] = quality
    else
      transformations[:saver] = { quality: quality }
    end

    attachment.variant(**transformations)
  end

  # What the photograph shows. Product names that already say "earrings" are
  # left alone so the alt text does not repeat the category.
  def piece_alt(product)
    name = product.name.to_s.strip
    category = product.category&.name.to_s.downcase
    return name if category.blank? || name.downcase.include?(category)

    "#{name}, #{category}"
  end

  def collection_image_alt(category)
    {
      "earrings" => "Gold-tone earring designs",
      "rings" => "Gold-tone fashion rings",
      "bracelets" => "Gold-tone bracelets",
      "kadas" => "Gold-tone kadas",
      "sets" => "Necklace sets",
      "handchains" => "Gold-tone hand chains",
      "chain-pendants" => "Gold-tone chains and pendants"
    }.fetch(category.slug, "#{category.name} from DeNshe")
  end

  def category_intro(category)
    {
      "earrings" => "Gold-tone and anti-tarnish earring designs. Hoops, studs, and drops, with the price beside each piece.",
      "rings" => "Adjustable fashion rings in gold-tone and anti-tarnish finishes. The price sits with each design.",
      "bracelets" => "Bracelets for the wrist, in gold-tone and stone-set designs. Prices are on each piece.",
      "kadas" => "Gold-tone kadas, from slim everyday cuffs to wider statement pieces. The price is on each one.",
      "sets" => "Necklace sets meant to be worn together. Each set is priced on its page.",
      "handchains" => "Hand chains from wrist to finger, in gold-tone designs. The price is on each piece.",
      "chain-pendants" => "Chains and pendants in gold-tone and silver-tone. The price sits with the design.",
      "combo" => "Pieces meant to be worn together. Each set is priced on its page."
    }.fetch(category.slug, "Shop #{category.name.downcase} from DeNshe. The price is on every piece.")
  end

  # Indian digit grouping: ₹1,299 and ₹1,20,000.
  # Units still free to select: stock, minus other carts, minus this shopper's own selection.
  def quantity_left(product)
    others = holds_by_others[product.id].to_i
    own = current_cart.quantity_of(product)
    own += 1 if current_cart.combo_product_ids.include?(product.id)
    [ product.stock_quantity - others - own, 0 ].max
  end

  def held_by_someone_else?(product)
    product.available_for_sale? && !current_cart.holding?(product) && quantity_left(product).zero?
  end

  def availability_copy(count)
    "#{count} available"
  end

  def holds_by_others
    @holds_by_others ||= CartHold.quantities_held_by_others(current_cart.session_key)
  end

  def price(amount, currency: nil)
    currency ||= current_market.currency
    amount = amount.to_d
    whole = amount == amount.to_i

    if currency == "AUD"
      number_to_currency(amount, unit: "A$", precision: whole ? 0 : 2, format: "%u%n")
    else
      number_to_currency(
        amount,
        unit: "₹",
        precision: whole ? 0 : 2,
        delimiter_pattern: /(\d+?)(?=(\d\d)+(\d)(?!\d))/
      )
    end
  end

  def listed_price(product)
    product.price_for(current_market)
  end

  def listed_compare_price(product)
    product.compare_at_for(current_market)
  end

  def listed_on_sale?(product)
    product.on_sale_for?(current_market)
  end

  def listed_discount(product)
    product.discount_percentage_for(current_market)
  end

  def brand
    Rails.application.config.x.brand
  end

  def payments_open?
    Rails.application.config.x.payments_open && RazorpayGateway.configured?
  end

  def shipping_amount_for(subtotal)
    return 0.to_d if australia?

    Checkout.shipping_amount_for(subtotal)
  end

  def shipping_label_for(subtotal)
    return "Confirmed with you" if australia?

    amount = shipping_amount_for(subtotal)
    amount.positive? ? price(amount) : "Complimentary"
  end

  def due_for(subtotal)
    subtotal.to_d + shipping_amount_for(subtotal)
  end

  def whatsapp_url(message = nil)
    return if brand.whatsapp.blank?

    url = "https://wa.me/#{brand.whatsapp}"
    message.present? ? "#{url}?text=#{CGI.escape(message)}" : url
  end

  def instagram_url
    "https://instagram.com/#{brand.instagram}" if brand.instagram.present?
  end

  def page_title(title = nil)
    content_for(:title) { title } if title
  end

  # index: false for pages that should not appear in Google (cart, checkout).
  def meta(description: nil, image: nil, type: "website", index: true)
    canonical = canonical_url
    picture = absolute_asset(image)
    title = content_for(:title).presence || brand.name

    content_for :meta do
      safe_join([
        tag.meta(name: "description", content: description),
        tag.link(rel: "canonical", href: canonical),
        tag.meta(name: "robots", content: index ? "index, follow" : "noindex, follow"),
        tag.meta(property: "og:site_name", content: brand.name),
        tag.meta(property: "og:type", content: type),
        tag.meta(property: "og:locale", content: (australia? ? "en_AU" : "en_IN")),
        tag.meta(property: "og:title", content: title),
        tag.meta(property: "og:description", content: description),
        tag.meta(property: "og:image", content: picture),
        tag.meta(property: "og:url", content: canonical),
        tag.meta(name: "twitter:card", content: "summary_large_image"),
        tag.meta(name: "twitter:title", content: title),
        tag.meta(name: "twitter:description", content: description),
        tag.meta(name: "twitter:image", content: picture)
      ].compact, "\n")
    end
  end

  # Page 2 of a listing is its own URL. Filtered views still point at the
  # clean collection so colour and price links do not create extra titles.
  def canonical_url
    url = "#{request.base_url}#{request.path}"
    page = params[:page].to_i
    return url unless page > 1 && bare_listing_page?

    "#{url}?page=#{page}"
  end

  def bare_listing_page?
    return false unless %w[products categories].include?(controller_name)
    return false if params[:q].present? || params[:material].present? || params[:colour].present? || params[:price].present? || params[:sort].present?

    true
  end

  def absolute_asset(image)
    source = image.presence || image_url("denshe-logo.jpg")
    source = source.to_s
    return source if source.start_with?("http://", "https://")

    path = source.start_with?("/") ? source : "/#{source}"
    "#{request.base_url}#{path}"
  end

  def structured_data(data)
    tag.script(json_escape(data.to_json).html_safe, type: "application/ld+json")
  end

  def product_structured_data(product, description:)
    data = {
      "@context" => "https://schema.org",
      "@type" => "Product",
      "name" => product.name,
      "description" => description,
      "brand" => { "@type" => "Brand", "name" => brand.name },
      "category" => product.category.name,
      "url" => piece_url(product.slug)
    }
    data["sku"] = product.sku if product.sku.present?
    data["color"] = product.colour if product.colour.present?
    data["material"] = product.material if product.material.present?

    image = product.display_image || product.gallery_images.first
    data["image"] = absolute_asset(url_for(image)) if image

    selling = product.price_for(current_market)
    if product.offered_in?(current_market) && selling.to_d.positive?
      data["offers"] = {
        "@type" => "Offer",
        "priceCurrency" => current_market.currency,
        "price" => format("%.2f", selling),
        "availability" => (product.available_for_sale? ? "https://schema.org/InStock" : "https://schema.org/OutOfStock"),
        "itemCondition" => "https://schema.org/NewCondition",
        "url" => piece_url(product.slug)
      }
    end

    data
  end

  def enquire_url(product)
    verb = product.available_for_sale? ? "I would like this piece" : "This piece has gone. Do you have something like it?"
    message = "Hello DeNshe, #{verb}: #{product.name} (#{piece_url(product.slug)})."
    whatsapp_url(message) || mail_url(subject: product.name, body: message)
  end

  def mail_url(subject:, body:)
    "mailto:#{brand.email}?subject=#{CGI.escape(subject)}&body=#{CGI.escape(body)}"
  end

  # Supplier notes from the intake seeds stay in the admin. The cabinet only
  # shows copy written for a customer.
  def customer_copy(text)
    text = text.to_s.strip
    return if text.blank?
    return if text.match?(/\A(Temporary name|From Celestia receipt|Update details when|Update when the piece)/i)

    text
  end

  def external_link?(url)
    url.to_s.start_with?("http://", "https://")
  end

  # Data attributes that let any save button talk to the jewellery box.
  def save_piece_params(product)
    image = product.gallery_images.first

    {
      jewellery_box_slug_param: product.slug,
      jewellery_box_name_param: product.name,
      jewellery_box_price_param: (price(product.price_for(current_market)) if product.offered_in?(current_market)),
      jewellery_box_url_param: piece_url(product.slug),
      jewellery_box_image_param: image ? url_for(piece_image_source(image, :thumb)) : nil
    }.compact
  end
end
