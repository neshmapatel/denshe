module Storefront
  class PotlisAndJarsController < BaseController
    def show
      CuratedGift.seed_defaults! if CuratedGift.none? || CuratedGift.find_by(slug: "noor").present?
      @curated_gifts = CuratedGift.active.ordered
      if params[:slug].present?
        @selected_gift = CuratedGift.active.find_by(slug: params[:slug])
      end
    end
  end
end
