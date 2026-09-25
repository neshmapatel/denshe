module Storefront
  class BaseController < ApplicationController
    layout "storefront"

    before_action :hold_for_launch

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

    def hold_for_launch
      return unless storefront_held?
      # The homepage stays on the launch screen until the date, even after preview.
      return if storefront_preview? && request.path != "/"

      render template: "storefront/pages/launching_soon", layout: "launching", status: :ok
    end

    def storefront_held?
      return false unless Rails.application.config.x.storefront_held

      Time.current < Rails.application.config.x.storefront_launches_at
    end

    def storefront_preview?
      cookies.signed[:storefront_preview] == "1"
    end
  end
end
