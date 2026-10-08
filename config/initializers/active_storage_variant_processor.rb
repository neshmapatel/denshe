# Production ships with libvips. A machine that only has ImageMagick should
# still resize photographs, otherwise the catalogue sends the original files.
begin
  require "image_processing/vips"
rescue LoadError, StandardError
  begin
    require "image_processing/mini_magick"
    Rails.application.config.active_storage.variant_processor = :mini_magick
  rescue LoadError, StandardError
    Rails.logger.warn("Active Storage cannot resize images: libvips and ImageMagick are both unavailable")
  end
end
