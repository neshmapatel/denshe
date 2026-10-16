module Storefront
  class MysteryBoxesController < BaseController
    def show
      redirect_to potlis_and_jars_path, status: :moved_permanently
    end

    def create
      redirect_to potlis_and_jars_path, status: :moved_permanently
    end

    def details
      redirect_to potlis_and_jars_path, status: :moved_permanently
    end

    def place
      redirect_to potlis_and_jars_path, status: :moved_permanently
    end
  end
end
