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
    # Every active piece is listed. The collection dropdown narrows it in one query.
    def catalogue
      @collection_lines = CollectionLine.all
      @collection_line = CollectionLine.find(params[:collection])

      products = Product.catalogue
        .with_storefront_includes
        .includes(:purchase)
        .order(Arel.sql("CASE WHEN products.stock_quantity > 0 THEN 0 ELSE 1 END, products.name ASC"))
      products = products.where(collection_line: @collection_line.key) if @collection_line
      products = products.load

      @products_by_category_id = products.group_by(&:category_id)
      @categories = Category.ordered.where(id: @products_by_category_id.keys)
      @piece_count = products.size
      @batches = products.filter_map(&:purchase).uniq.sort_by { |purchase| [ purchase.purchased_on || Date.new(1900, 1, 1), purchase.reference ] }
    end
  end
end
