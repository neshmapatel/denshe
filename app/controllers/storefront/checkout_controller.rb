module Storefront
  class CheckoutController < BaseController
    before_action :require_pieces, only: [ :new, :create ]
    before_action :load_order, only: :payment

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
    end

    private

    def require_pieces
      redirect_to cart_path, alert: "Select a piece before checkout." if current_cart.empty?
    end

    def load_order
      @order = Order.includes(:order_items, :shipping_address, :billing_address).find_by(id: session[:order_id])
      redirect_to cart_path, alert: "Enter your details before payment." if @order.nil?
    end

    def checkout_params
      params.require(:checkout).permit(
        :name, :phone, :email, :line1, :line2, :city, :state, :pin_code, :billing_same,
        :billing_line1, :billing_line2, :billing_city, :billing_state, :billing_pin_code
      )
    end
  end
end
