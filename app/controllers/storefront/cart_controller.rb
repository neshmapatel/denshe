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

    def create_combo
      combo = Combo.active.find_by!(slug: params[:slug])
      picks = params[:picks].respond_to?(:to_unsafe_h) ? params[:picks].to_unsafe_h : {}

      case current_cart.add_combo(combo, picks)
      when :added
        redirect_to cart_path, notice: "#{combo.name} is selected."
      when :incomplete
        redirect_to combo_path(combo.slug), alert: "Choose #{combo.choice_summary}."
      when :held
        redirect_to combo_path(combo.slug), alert: "One of those pieces is already selected."
      when :not_offered
        redirect_to combo_path(combo.slug), alert: "#{combo.name} is part of the India shop."
      else
        redirect_to combo_path(combo.slug), alert: "#{combo.name} is no longer available."
      end
    end

    def destroy_combo
      current_cart.remove_combo(params[:token])
      redirect_to cart_path, notice: "That combo was removed."
    end
  end
end
