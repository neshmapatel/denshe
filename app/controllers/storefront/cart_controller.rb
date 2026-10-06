module Storefront
  class CartController < BaseController
    def show
    end

    def create
      product = Product.find_by_slug!(params[:slug], scope: Product.available)
      unless product.offered_in?(current_market)
        redirect_back fallback_location: piece_path(product.slug), alert: "#{product.name} is part of the India shop."
        return
      end

      case current_cart.add(product)
      when :added
        redirect_back fallback_location: shop_path, notice: "#{product.name} is selected."
      when :held
        redirect_back fallback_location: shop_path, alert: "Someone has already added #{product.name} to their cart."
      else
        redirect_back fallback_location: shop_path, alert: "#{product.name} is no longer available."
      end
    end

    def destroy
      product = Product.find_by_slug!(params[:slug])
      current_cart.remove(product)
      redirect_to cart_path, notice: "#{product.name} was removed."
    end
  end
end
