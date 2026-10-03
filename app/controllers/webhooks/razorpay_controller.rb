module Webhooks
  # Razorpay server-to-server events. Marks the order paid when the browser
  # never gets the Standard Checkout handler (common with UPI QR on another phone).
  class RazorpayController < ApplicationController
    skip_before_action :verify_authenticity_token

    def create
      body = request.raw_post
      signature = request.headers["X-Razorpay-Signature"].to_s
      unless RazorpayGateway.valid_webhook_signature?(body, signature)
        return head :unauthorized
      end

      event = JSON.parse(body)
      case event["event"]
      when "payment.captured", "order.paid"
        capture_from(event)
      when "payment.failed"
        fail_from(event)
      end

      head :ok
    rescue JSON::ParserError
      head :bad_request
    end

    private

    def capture_from(event)
      entity = payment_entity(event)
      return if entity.blank?

      gateway_order_id = entity["order_id"].presence
      gateway_payment_id = entity["id"].presence
      return if gateway_order_id.blank?

      payment = Payment.find_by(gateway_order_id: gateway_order_id)
      return if payment.nil?

      payment.order.capture_payment!(
        gateway_payment_id: gateway_payment_id,
        payment: payment
      )
    end

    def fail_from(event)
      entity = payment_entity(event)
      return if entity.blank?

      payment = Payment.find_by(gateway_order_id: entity["order_id"].to_s)
      return if payment.nil? || payment.paid? || payment.order.payment_paid?

      error = entity["error"] || {}
      payment.update!(
        status: :failed,
        gateway_payment_id: entity["id"].presence || payment.gateway_payment_id,
        error_code: error["code"].presence || entity["error_code"],
        error_message: (error["description"].presence || entity["error_description"] || "Payment failed.").to_s.truncate(2_000),
        error_source: error["source"],
        error_step: error["step"],
        error_reason: error["reason"]
      )
      payment.order.update!(payment_status: :payment_failed) unless payment.order.payment_paid?
    end

    def payment_entity(event)
      payload = event["payload"] || {}
      payment = payload.dig("payment", "entity")
      return payment if payment.present?

      # order.paid includes the order entity; payments may be nested.
      order = payload.dig("order", "entity") || {}
      payments = Array(order.dig("payments") || payload.dig("payment", "entities"))
      first = payments.first
      return first if first.is_a?(Hash)

      {
        "id" => nil,
        "order_id" => order["id"]
      }
    end
  end
end
