module Storefront
  class PagesController < BaseController
    def home
      @looks = australia? ? Combo.none : Combo.active.ordered.includes(groups: { products: [ :category, { images_attachments: { blob: :variant_records } } ] })
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

    def karamsad
      @featured_pieces = Product.catalogue_for(current_market)
        .with_storefront_includes
        .where(status: :active)
        .order(Arel.sql("CASE WHEN products.stock_quantity > 0 THEN 0 ELSE 1 END, products.bestseller DESC, products.featured DESC, products.created_at DESC"))
        .limit(8)
    end

    def anand
      @featured_pieces = Product.catalogue_for(current_market)
        .with_storefront_includes
        .where(status: :active)
        .order(Arel.sql("CASE WHEN products.stock_quantity > 0 THEN 0 ELSE 1 END, products.bestseller DESC, products.featured DESC, products.created_at DESC"))
        .limit(8)
    end

    def vidya_nagar
      @featured_pieces = Product.catalogue_for(current_market)
        .with_storefront_includes
        .where(status: :active)
        .order(Arel.sql("CASE WHEN products.stock_quantity > 0 THEN 0 ELSE 1 END, products.selling_price ASC, products.featured DESC"))
        .limit(8)
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
      @looks = Combo.active.ordered.includes(groups: { products: [ :category, { images_attachments: { blob: :variant_records } } ] })
    end
  end
end
