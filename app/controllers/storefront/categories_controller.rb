module Storefront
  class CategoriesController < BaseController
    include ProductListing

    def index
      @categories = Category.ordered.where(id: Product.catalogue_for(current_market).select(:category_id))
    end

    def show
      @category = Category.find_by!(slug: params[:slug])
      @heading = @category.name
      load_products(scope: Product.catalogue_for(current_market).where(category_id: @category.id))
      render "storefront/products/index"
    end
  end
end
