module StorefrontHelper
  # Width/height caps per slot. Portrait crops suit jewellery photography.
  IMAGE_SIZES = {
    thumb: [ 200, 267 ],
    card: [ 700, 933 ],
    feature: [ 1100, 1467 ],
    stage: [ 1400, 1867 ]
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

  def piece_image(attachment, size: :card, **options)
    return if attachment.blank?

    image_tag piece_image_source(attachment, size),
              loading: options.delete(:loading) || "lazy",
              decoding: "async",
              **options
  end

  def piece_image_source(attachment, size)
    return attachment unless StorefrontHelper.variants_supported? && attachment.variable?

    # WebP: the originals are PNG straight off a phone, so the same picture is
    # an order of magnitude smaller here with no visible difference.
    attachment.variant(format: :webp, resize_to_limit: IMAGE_SIZES.fetch(size), saver: { quality: 82 })
  end

  # Indian digit grouping: ₹1,299 and ₹1,20,000.
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
