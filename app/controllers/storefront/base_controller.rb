module Storefront
  class BaseController < ApplicationController
    layout "storefront"

    before_action :hold_for_launch
    before_action :resolve_market

    helper_method :nav_categories, :category_counts, :nav_collection_lines, :collection_line_counts,
                  :catalogue_live?, :brand, :current_cart,
                  :current_market, :australia?, :market_switch_path

    private

    # Only collections that have something to sell reach the navigation, so a
    # shopper never lands on an empty shelf.
    def nav_categories
      @nav_categories ||= Category.ordered
        .where(id: Product.catalogue_for(current_market).select(:category_id))
        .to_a
    end

    def category_counts
      @category_counts ||= Product.catalogue_for(current_market).group(:category_id).count
    end

    # Western appears once it has pieces. Indian stays listed so the festive
    # page can say it is still being finished.
    def nav_collection_lines
      @nav_collection_lines ||= CollectionLine.all.select do |line|
        line.indian? || collection_line_counts[line.slug].to_i.positive?
      end
    end

    def collection_line_counts
      @collection_line_counts ||= begin
        catalogue = Product.catalogue_for(current_market)
        CollectionLine::SLUGS.index_with { |slug| catalogue.public_send(slug).count }
      end
    end

    def catalogue_live?
      nav_categories.any?
    end

    def brand
      Rails.application.config.x.brand
    end

    def current_cart
      @current_cart ||= Cart.new(session, market: current_market)
    end

    def current_market
      @current_market ||= Market.india
    end

    def australia?
      current_market.australia?
    end

    def market_switch_path(code)
      url_for(request.path_parameters.merge(request.query_parameters.symbolize_keys.except(:market)).merge(market: code))
    end

    # A cookie wins. Otherwise the edge country header opens Australia for
    # visitors there, and everyone else sees the India shop. ?market= switches.
    def resolve_market
      requested = params[:market].to_s
      if request.get? && Market::CODES.include?(requested)
        cookies.permanent[:market] = { value: requested, httponly: true, same_site: :lax }
        redirect_to url_for(request.path_parameters.merge(request.query_parameters.symbolize_keys.except(:market)))
        return
      end

      unless Market::CODES.include?(cookies[:market])
        country = request.headers["CF-IPCountry"].to_s.upcase
        cookies.permanent[:market] = { value: (country == "AU" ? "au" : "in"), httponly: true, same_site: :lax }
      end

      @current_market = Market.resolve(cookies[:market])
    end

    def hold_for_launch
      return unless Rails.application.config.x.storefront_held
      return if cookies.signed[:storefront_preview] == "1"

      render template: "storefront/pages/launching_soon", layout: "launching", status: :ok
    end
  end
end
