module ApplicationHelper
  def fullscreen_button(attachment, alt:, preview: nil, **options)
    tag.button(
      type: "button",
      class: [ "lightbox-trigger", options.delete(:class) ].compact.join(" "),
      data: { fullscreen_src: url_for(attachment), fullscreen_alt: alt },
      aria: { label: "View #{alt.presence || "photograph"} full screen" }
    ) do
      image_tag preview || url_for(attachment), alt: "", **options
    end
  end
end
