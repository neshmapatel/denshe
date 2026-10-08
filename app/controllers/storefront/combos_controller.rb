module Storefront
  class CombosController < BaseController
    def index
      @combos = Combo.active.ordered.includes(:groups)
    end

    def show
      @combo = Combo.active
        .includes(groups: { products: { images_attachments: :blob } })
        .find_by!(slug: params[:slug])
    end
  end
end
