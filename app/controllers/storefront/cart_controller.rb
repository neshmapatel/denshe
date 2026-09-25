module Storefront
  class CartController < BaseController
    def show
    end

    def create
      product = Product.available.find_by!(slug: params[:slug])

      if current_cart.add(product)
        redirect_back fallback_location: shop_path, notice: "#{product.name} is selected."
      else
        redirect_back fallback_location: shop_path, alert: "#{product.name} is no longer available."
      end
    end

    def destroy
      product = Product.find_by!(slug: params[:slug])
      current_cart.remove(product)
      redirect_to cart_path, notice: "#{product.name} was removed."
    end
  end
end
