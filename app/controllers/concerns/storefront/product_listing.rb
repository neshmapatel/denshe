module Storefront
  # Shared between the full shop and a single collection: both render the same
  # filterable grid, only the starting scope differs.
  module ProductListing
    extend ActiveSupport::Concern

    included do
      helper_method :listing_params, :listing_url
    end

    private

    def load_products(scope: Product.available)
      @filter = ProductFilter.new(params, scope: scope)
      @pagination = Paginator.new(@filter.results.with_storefront_includes, page: params[:page])
      @products = @pagination.records
    end

    # Keeps the current filters intact while changing one of them.
    def listing_params(overrides = {})
      params
        .slice(:q, :material, :colour, :price, :sort)
        .permit(:q, :material, :colour, :price, :sort)
        .to_h
        .symbolize_keys
        .merge(overrides)
        .compact_blank
    end

    def listing_url(overrides = {})
      url_for(request.path_parameters.merge(listing_params(overrides)))
    end
  end
end
