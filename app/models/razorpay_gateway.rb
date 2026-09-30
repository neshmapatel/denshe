require "openssl"

# Server-side Razorpay calls. The key id may be shown to the browser.
# The key secret must not.
module RazorpayGateway
  class << self
    attr_accessor :orders
  end
  self.orders = Razorpay::Order

  module_function

  def configured?
    key_id.present? && key_secret.present?
  end

  def key_id
    ENV["RAZORPAY_KEY_ID"].presence
  end

  def create_order(amount:, receipt:)
    Razorpay.setup(key_id, key_secret)
    orders.create(amount: amount, currency: "INR", receipt: receipt.to_s)
  end

  # Razorpay signs "#{order_id}|#{payment_id}" with the key secret.
  def valid_signature?(order_id:, payment_id:, signature:)
    return false if order_id.blank? || payment_id.blank? || signature.blank? || key_secret.blank?

    expected = OpenSSL::HMAC.hexdigest("SHA256", key_secret, "#{order_id}|#{payment_id}")
    return false unless signature.bytesize == expected.bytesize

    ActiveSupport::SecurityUtils.secure_compare(expected, signature)
  end

  def key_secret
    ENV["RAZORPAY_KEY_SECRET"].presence
  end
end