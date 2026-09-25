module Storefront
  class CategoriesController < BaseController
    include ProductListing

    def index
      @categories = Category.ordered.stocked
    end

    def show
      @category = Category.find_by!(slug: params[:slug])
      @heading = @category.name
      load_products(scope: @category.available_products)
      render "storefront/products/index"
    end
  end
end
