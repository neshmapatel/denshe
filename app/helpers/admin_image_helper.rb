module AdminImageHelper
  # Admin screens only ever show small previews, so never hand the browser the
  # original photograph — those are 2-3 MB each and a list of them stalls.
  def admin_thumb(attachment, px)
    return if attachment.blank?
    return attachment unless StorefrontHelper.variants_supported? && attachment.variable?

    attachment.variant(format: :webp, resize_to_limit: [ px * 2, px * 2 ], saver: { quality: 78 })
  end

  def admin_thumb_tag(attachment, px, **options)
    source = admin_thumb(attachment, px)
    return if source.blank?

    image_tag url_for(source), loading: "lazy", decoding: "async", **options
  end
end
