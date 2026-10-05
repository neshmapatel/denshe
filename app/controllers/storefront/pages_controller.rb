module Storefront
  class PagesController < BaseController
    def home
    end

    def story
    end

    def care
    end

    def contact
    end

    def privacy
    end

    def terms
    end

    def shipping_returns
    end

    def jewellery_box
    end

    # A quiet price list for people who prefer to message or ask in person.
    def catalogue
      products = Product.catalogue_for(current_market)
        .with_storefront_includes
        .order(Arel.sql("CASE WHEN products.stock_quantity > 0 THEN 0 ELSE 1 END, products.name ASC"))

      @products_by_category_id = products.group_by(&:category_id)
      @categories = Category.ordered.where(id: @products_by_category_id.keys)
      @piece_count = products.size
    end
  end
end
