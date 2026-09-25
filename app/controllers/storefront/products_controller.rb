module Storefront
  class ProductsController < BaseController
    include ProductListing

    def index
      @heading = @filter_heading = "Every piece"
      load_products
    end

    def show
      # Sold pieces stay reachable so shared links and search results never 404;
      # the page itself makes the sold-out state obvious.
      @product = Product.active.with_storefront_includes.find_by!(slug: params[:slug])
      @related = related_pieces
    end

    private

    def related_pieces
      Product.available
        .with_storefront_includes
        .where(category_id: @product.category_id)
        .where.not(id: @product.id)
        .order(Arel.sql("products.featured DESC, RANDOM()"))
        .limit(4)
    end
  end
end
