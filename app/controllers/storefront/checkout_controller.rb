module Storefront
  class CheckoutController < BaseController
    before_action :require_pieces, only: [ :new, :create ]
    before_action :load_order, only: [ :payment, :success, :create_payment, :verify_payment, :payment_status, :record_payment_failure ]

    def new
      @checkout = Checkout.new
    end

    def create
      @checkout = Checkout.from_params(checkout_params)
      order = @checkout.place!(current_cart)

      if order
        current_cart.clear
        session[:order_id] = order.id
        redirect_to checkout_payment_path
      else
        render :new, status: :unprocessable_entity
      end
    end

    def payment
      redirect_to checkout_success_path if @order.payment_paid?
    end

    def success
      redirect_to checkout_payment_path unless @order.payment_paid?
    end

    def create_payment
      amount = (@order.total.to_d * 100).round
      if amount < 100
        return render json: { error: "Amount must be at least ₹1." }, status: :bad_request
      end
      unless RazorpayGateway.configured?
        return render json: { error: "Payment is not configured." }, status: :internal_server_error
      end

      razorpay_order = RazorpayGateway.create_order(amount: amount, receipt: @order.number)
      @order.payments.create!(
        payment_gateway: PaymentGateway.razorpay,
        amount: @order.total,
        currency: razorpay_order.currency.presence || "INR",
        status: :pending,
        gateway_order_id: razorpay_order.id
      )
      @order.update!(payment_status: :payment_pending, payment_method: "razorpay")
      session[:razorpay_order_id] = razorpay_order.id
      render json: {
        order_id: razorpay_order.id,
        amount: razorpay_order.amount,
        currency: razorpay_order.currency
      }
    rescue Razorpay::Error => error
      record_gateway_error(error)
      status = error.status.to_i == 401 ? :unauthorized : :internal_server_error
      render json: { error: "Payment could not be started." }, status: status
    end

    def verify_payment
      order_id = params[:razorpay_order_id].to_s
      payment_id = params[:razorpay_payment_id].to_s
      signature = params[:razorpay_signature].to_s
      payment = attempt_for(order_id)

      verified = order_id == session[:razorpay_order_id] &&
        RazorpayGateway.valid_signature?(order_id: order_id, payment_id: payment_id, signature: signature)
      unless verified
        note_failure(payment, error_message: "Payment could not be verified.", gateway_payment_id: payment_id)
        return render json: { error: "Payment could not be verified." }, status: :bad_request
      end

      @order.capture_payment!(gateway_payment_id: payment_id, payment: payment)
      render json: { ok: true, redirect: checkout_success_path }
    end

    def payment_status
      latest = @order.payments.order(created_at: :desc).first
      failed = @order.payment_failed? || latest&.failed?
      render json: {
        paid: @order.payment_paid?,
        failed: failed && !@order.payment_paid?,
        error: (failed && !@order.payment_paid? ? latest&.error_message : nil),
        redirect: (@order.payment_paid? ? checkout_success_path : nil)
      }
    end

    def record_payment_failure
      payment = attempt_for(params[:gateway_order_id].presence || session[:razorpay_order_id])
      return render json: { error: "Payment attempt was not found." }, status: :not_found if payment.nil? || payment.paid?
      return render json: { ok: true, paid: true, redirect: checkout_success_path } if @order.payment_paid?

      if params[:status] == "cancelled"
        payment.update!(status: :cancelled, error_message: params[:error_message].presence || "Payment was cancelled.")
      else
        note_failure(
          payment,
          error_code: params[:error_code],
          error_message: params[:error_message].presence || "Payment failed.",
          error_source: params[:error_source],
          error_step: params[:error_step],
          error_reason: params[:error_reason],
          gateway_payment_id: params[:gateway_payment_id]
        )
      end
      @order.update!(payment_status: :payment_failed) unless @order.payment_paid?
      render json: { ok: true }
    end

    private

    def require_pieces
      redirect_to cart_path, alert: "Select a piece before checkout." if current_cart.empty?
    end

    def load_order
      @order = Order.includes(:order_items, :shipping_address, :billing_address, :payments).find_by(id: session[:order_id])
      redirect_to cart_path, alert: "Enter your details before payment." if @order.nil?
    end

    def attempt_for(order_id)
      return if order_id.blank? || order_id != session[:razorpay_order_id]

      @order.payments.where(gateway_order_id: order_id).order(created_at: :desc).first
    end

    def note_failure(payment, error_code: nil, error_message:, error_source: nil, error_step: nil, error_reason: nil, gateway_payment_id: nil)
      return if payment.nil? || payment.paid?

      payment.update!(
        status: :failed,
        gateway_payment_id: gateway_payment_id.presence || payment.gateway_payment_id,
        error_code: error_code.presence,
        error_message: error_message.to_s.truncate(2_000),
        error_source: error_source.presence,
        error_step: error_step.presence,
        error_reason: error_reason.presence
      )
      @order.update!(payment_status: :payment_failed) unless @order.payment_paid?
    end

    def record_gateway_error(error)
      @order.payments.create!(
        payment_gateway: PaymentGateway.razorpay,
        amount: @order.total,
        currency: "INR",
        status: :failed,
        error_code: error.code,
        error_message: error.message.presence || "Payment could not be started."
      )
      @order.update!(payment_status: :payment_failed, payment_method: "razorpay") unless @order.payment_paid?
    end

    def checkout_params
      params.require(:checkout).permit(
        :name, :phone, :email, :line1, :line2, :city, :state, :pin_code, :billing_same,
        :billing_line1, :billing_line2, :billing_city, :billing_state, :billing_pin_code
      )
    end
  end
end
