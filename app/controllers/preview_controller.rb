class PreviewController < ApplicationController
  def create
    unless preview_token?(params[:token])
      head :not_found
      return
    end

    cookies.permanent.signed[:storefront_preview] = {
      value: "1",
      httponly: true,
      same_site: :lax
    }
    redirect_to root_path
  end

  def destroy
    cookies.delete(:storefront_preview)
    redirect_to root_path
  end

  private

  def preview_token?(given)
    expected = Rails.application.config.x.storefront_preview_token.to_s
    return false if expected.blank? || given.blank?

    ActiveSupport::SecurityUtils.secure_compare(
      Digest::SHA256.hexdigest(given.to_s),
      Digest::SHA256.hexdigest(expected)
    )
  end
end