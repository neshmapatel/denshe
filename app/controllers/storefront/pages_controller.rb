module Storefront
  class PagesController < BaseController
    SHELF_SIZE = 8

    def home
      @collections = nav_categories.first(6)
      @piece_count = category_counts.values.sum

      arrivals = Product.available.where(new_arrival: true).order(created_at: :desc)
      @arrivals_handpicked = arrivals.exists?
      @new_arrivals = shelf(arrivals)

      @featured = featured_shelf
      @price = MysteryBoxPreference.new.box_price.presence || 599
    end

    def story
    end

    def care
    end

    def contact
    end

    def mystery_box
      @price = MysteryBoxPreference.new.box_price.presence || 599
    end

    def jewellery_box
    end

    private

    # Home shelves fall back to the newest pieces so the page still reads well
    # before anyone has ticked "featured" or "new arrival" in the admin.
    def shelf(scope, excluding: [])
      pieces = scope.with_storefront_includes.limit(SHELF_SIZE).to_a
      return pieces if pieces.size >= 4

      excluded = pieces.map(&:id) + excluding.map(&:id)
      filler = Product.available.with_storefront_includes.order(created_at: :desc)
      filler = filler.where.not(id: excluded) if excluded.any?
      filler = filler.limit(SHELF_SIZE - pieces.size)

      pieces + filler.to_a
    end

    # Featured stays honest: only pieces marked in the admin, and never a repeat
    # of whatever the first shelf already showed.
    def featured_shelf
      scope = Product.available.where(featured: true).with_storefront_includes.order(updated_at: :desc)
      ids = @new_arrivals.map(&:id)
      scope = scope.where.not(id: ids) if ids.any?
      scope.limit(SHELF_SIZE).to_a
    end
  end
end
