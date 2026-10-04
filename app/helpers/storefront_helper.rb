module StorefrontHelper
  # Width/height caps per slot. Portrait crops suit jewellery photography.
  IMAGE_SIZES = {
    thumb: [ 200, 267 ],
    card: [ 700, 933 ],
    feature: [ 1100, 1467 ],
    stage: [ 1400, 1867 ]
  }.freeze

  # Lifestyle art that stands in for a product photo on a collection tile.
  COLLECTION_COVERS = {
    "bracelets" => "collection-bracelets.jpg",
    "earrings" => "collection-earrings.jpg",
    "chain-pendants" => "collection-chain-pendants.jpg"
  }.freeze

  # Active Storage needs libvips (or ImageMagick) to build variants. Production
  # has it; a bare development machine often does not, so fall back to the
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
    return attachment unless StorefrontHelper.variants_supported? && attachment.variable?

    attachment.variant(resize_to_limit: IMAGE_SIZES.fetch(size), saver: { quality: 82 })
  end

  # Indian digit grouping: ₹1,299 and ₹1,20,000.
  # Units still free to select: stock, minus other carts, minus this shopper's own selection.
  def quantity_left(product)
    others = holds_by_others[product.id].to_i
    [ product.stock_quantity - others - current_cart.quantity_of(product), 0 ].max
  end

  def held_by_someone_else?(product)
    product.available_for_sale? && !current_cart.include?(product) && quantity_left(product).zero?
  end

  def availability_copy(count)
    "#{count} available"
  end

  def holds_by_others
    @holds_by_others ||= CartHold.quantities_held_by_others(current_cart.session_key)
  end

  def price(amount)
    amount = amount.to_d
    number_to_currency(
      amount,
      unit: "₹",
      precision: amount == amount.to_i ? 0 : 2,
      delimiter_pattern: /(\d+?)(?=(\d\d)+(\d)(?!\d))/
    )
  end

  def brand
    Rails.application.config.x.brand
  end

  def payments_open?
    Rails.application.config.x.payments_open && RazorpayGateway.configured?
  end

  def shipping_amount_for(subtotal)
    Checkout.shipping_amount_for(subtotal)
  end

  def shipping_label_for(subtotal)
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

  def meta(description: nil, image: nil, type: "website")
    content_for :meta do
      safe_join([
        tag.meta(name: "description", content: description),
        tag.meta(property: "og:site_name", content: brand.name),
        tag.meta(property: "og:type", content: type),
        tag.meta(property: "og:title", content: content_for(:title) || brand.name),
        tag.meta(property: "og:description", content: description),
        tag.meta(property: "og:image", content: image || image_url("denshe-logo.jpg")),
        tag.meta(property: "og:url", content: request.original_url),
        tag.meta(name: "twitter:card", content: "summary_large_image")
      ].compact, "\n")
    end
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
      jewellery_box_price_param: price(product.selling_price),
      jewellery_box_url_param: piece_url(product.slug),
      jewellery_box_image_param: image ? url_for(piece_image_source(image, :thumb)) : nil
    }.compact
  end
end
