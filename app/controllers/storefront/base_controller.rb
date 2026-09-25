module Storefront
  class BaseController < ApplicationController
    layout "storefront"

    helper_method :nav_categories, :category_counts, :catalogue_live?, :brand, :current_cart

    private

    # Only collections that have something to sell reach the navigation, so a
    # shopper never lands on an empty shelf.
    def nav_categories
      @nav_categories ||= Category.ordered.stocked.to_a
    end

    def category_counts
      @category_counts ||= Product.available.group(:category_id).count
    end

    def catalogue_live?
      nav_categories.any?
    end

    def brand
      Rails.application.config.x.brand
    end

    def current_cart
      @current_cart ||= Cart.new(session)
    end
  end
end
