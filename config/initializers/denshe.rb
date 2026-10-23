# Brand-level details the storefront renders in the header, footer, and contact
# page. Set the environment variables before launch; anything left blank is
# simply not rendered rather than showing a dead link.
Rails.application.config.x.brand = ActiveSupport::OrderedOptions.new.merge(
  name: "DeNshe Jewellery",
  tagline: "Jewellery, chosen with you in mind",
  email: ENV.fetch("DENSHE_CONTACT_EMAIL", "denshe1713@gmail.com"),
  order_notify_email: ENV.fetch("ORDER_NOTIFY_EMAIL", ENV.fetch("DENSHE_CONTACT_EMAIL", "denshe1713@gmail.com")),
  # Digits only, including the country code, e.g. 919876543210.
  whatsapp: ENV.fetch("DENSHE_WHATSAPP_NUMBER", "919586488320"),
  phone: ENV.fetch("DENSHE_PHONE_NUMBER", "+91 9586488320"),
  instagram: ENV.fetch("DENSHE_INSTAGRAM_HANDLE", "denshe__"),
  city: "Anand, Gujarat",
  operating_address: ENV.fetch("DENSHE_OPERATING_ADDRESS", "Anand, Gujarat, India — 388001"),
  support_hours: "Monday to Saturday, 10:00 AM – 6:00 PM IST",
  ships_from: "Dispatched from Anand, Gujarat",
  standard_shipping: 80,
  free_shipping_above: 599,
  dispatch_window: "2 to 4 working days"
)

# Public storefront is live and open. Defaults to false so reviewers and shoppers
# see the active site without requiring extra environment variables.
Rails.application.config.x.storefront_held = ActiveModel::Type::Boolean.new.cast(
  ENV.fetch("STOREFRONT_HELD", "false")
)
Rails.application.config.x.storefront_preview_token = ENV.fetch("STOREFRONT_PREVIEW_TOKEN", "navy-atelier")

# Online checkout opens when Razorpay credentials are configured.
Rails.application.config.x.payments_open = ActiveModel::Type::Boolean.new.cast(
  ENV.fetch("PAYMENTS_OPEN", "false")
)

# Google Analytics 4 measurement ID, e.g. G-XXXXXXXXXX. Blank means no tag is rendered.
Rails.application.config.x.google_analytics_id = ENV["GOOGLE_ANALYTICS_ID"].to_s.strip.presence
