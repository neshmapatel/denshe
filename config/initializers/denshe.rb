# Brand-level details the storefront renders in the header, footer, and contact
# page. Set the environment variables before launch; anything left blank is
# simply not rendered rather than showing a dead link.
Rails.application.config.x.brand = ActiveSupport::OrderedOptions.new.merge(
  name: "DeNshe Jewellery",
  tagline: "Jewellery, chosen with you in mind",
  email: ENV.fetch("DENSHE_CONTACT_EMAIL", "denshe1713@gmail.com"),
  order_notify_email: ENV.fetch("ORDER_NOTIFY_EMAIL", ENV.fetch("DENSHE_CONTACT_EMAIL", "denshe1713@gmail.com")),
  # Digits only, including the country code, e.g. 919876543210.
  whatsapp: ENV["DENSHE_WHATSAPP_NUMBER"].presence,
  instagram: ENV.fetch("DENSHE_INSTAGRAM_HANDLE", "denshe__"),
  city: "Anand, Gujarat",
  ships_from: "Dispatched from Anand, Gujarat",
  standard_shipping: 80,
  free_shipping_above: 999,
  dispatch_window: "2 to 4 working days"
)

# Public storefront stays on the launching page in production until this is
# turned off. Visit /preview/<token> once to open the full site in that browser.
Rails.application.config.x.storefront_held = ActiveModel::Type::Boolean.new.cast(
  ENV.fetch("STOREFRONT_HELD", Rails.env.production?.to_s)
)
Rails.application.config.x.storefront_preview_token = ENV.fetch("STOREFRONT_PREVIEW_TOKEN", "navy-atelier")

# Online checkout stays quiet until Razorpay website approval is complete.
Rails.application.config.x.payments_open = ActiveModel::Type::Boolean.new.cast(
  ENV.fetch("PAYMENTS_OPEN", (!Rails.env.production?).to_s)
)

# Google Analytics 4 measurement ID, e.g. G-XXXXXXXXXX. Blank means no tag is rendered.
Rails.application.config.x.google_analytics_id = ENV["GOOGLE_ANALYTICS_ID"].to_s.strip.presence
