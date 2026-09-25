# Brand-level details the storefront renders in the header, footer, and contact
# page. Set the environment variables before launch; anything left blank is
# simply not rendered rather than showing a dead link.
Rails.application.config.x.brand = ActiveSupport::OrderedOptions.new.merge(
  name: "DeNshe",
  tagline: "Jewellery, chosen with you in mind",
  email: ENV.fetch("DENSHE_CONTACT_EMAIL", "hello@denshe.in"),
  # Digits only, including the country code, e.g. 919876543210.
  whatsapp: ENV["DENSHE_WHATSAPP_NUMBER"].presence,
  instagram: ENV.fetch("DENSHE_INSTAGRAM_HANDLE", "denshe.jewellery"),
  city: "Mumbai, India",
  ships_from: "Dispatched from Mumbai",
  free_shipping_above: 999,
  dispatch_window: "2 to 4 working days"
)
