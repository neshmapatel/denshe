class ApplicationController < ActionController::Base
  # Allow Instagram-in-app and older mobile browsers during the first launch.
  # Re-enable modern-browser gating later if we want a stricter storefront.
  # allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  protect_from_forgery with: :exception
end
