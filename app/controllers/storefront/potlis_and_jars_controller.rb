module Storefront
  class PotlisAndJarsController < BaseController
    def show
      @curated_gifts = CuratedGift.active.ordered
      if params[:slug].present?
        @selected_gift = CuratedGift.active.find_by(slug: params[:slug])
      end
    end
  end
end
