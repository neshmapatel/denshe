module Storefront
  class CombosController < BaseController
    def index
      @combos = Combo.active.ordered.includes(groups: { products: [ :category, { images_attachments: { blob: :variant_records } } ] })
    end

    def show
      @combo = Combo.active
        .includes(groups: { products: { images_attachments: :blob } })
        .find_by!(slug: params[:slug])
    end
  end
end
