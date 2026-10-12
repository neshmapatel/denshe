module Storefront
  class ProductsController < BaseController
    include ProductListing

    def index
      @heading = @filter_heading = "Every piece"
      load_products
    end

    def photo
      requested = params[:slug].to_s
      product = Product.find_by_slug!(requested, scope: Product.active)
      image = product.catalogue_photo
      raise ActiveRecord::RecordNotFound if image.nil?

      if requested != product.public_slug
        redirect_to piece_photo_path(product.public_slug), status: :moved_permanently
        return
      end

      blob = image.blob
      expires_in 12.hours, public: true
      send_file blob.service.path_for(blob.key),
        type: blob.content_type.presence || "image/jpeg",
        disposition: "inline",
        filename: "#{product.public_slug}#{share_photo_extension(blob)}"
    end

    def show
      # Sold pieces stay reachable so shared links and search results never 404;
      # the page itself makes the sold-out state obvious.
      requested = params[:slug].to_s
      @product = Product.find_by_slug!(requested, scope: Product.active.with_storefront_includes.includes(clips_attachments: :blob))
      if requested != @product.public_slug
        redirect_to piece_path(@product.public_slug), status: :moved_permanently
        return
      end

      @related = related_pieces
    end

    private

    def share_photo_extension(blob)
      ext = blob.filename.extension_with_delimiter.to_s.downcase
      ext.match?(/\A\.(jpe?g|png|webp|gif)\z/) ? ext : ".jpg"
    end

    def related_pieces
      Product.catalogue_for(current_market)
        .with_storefront_includes
        .where(category_id: @product.category_id, collection_line: @product.collection_line)
        .where.not(id: @product.id)
        .order(Arel.sql("CASE WHEN products.stock_quantity > 0 THEN 0 ELSE 1 END, products.featured DESC, RANDOM()"))
        .limit(4)
    end
  end
end
