module Storefront
  class CategoriesController < BaseController
    include ProductListing

    def index
      catalogue = Product.catalogue_for(current_market)
      @collection_lines = CollectionLine.all.select do |line|
        catalogue.public_send(line.key).exists?
      end
      @categories = Category.ordered.where(id: catalogue.select(:category_id))
    end

    def show
      if (@collection_line = CollectionLine.find(params[:slug]))
        @heading = @collection_line.name
        load_products(scope: Product.catalogue_for(current_market).public_send(@collection_line.key))
        render "storefront/products/index"
      else
        @category = Category.find_by!(slug: params[:slug])
        @heading = @category.name
        load_products(scope: Product.catalogue_for(current_market).where(category_id: @category.id))
        render "storefront/products/index"
      end
    end
  end
end
