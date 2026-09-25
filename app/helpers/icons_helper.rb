module IconsHelper
  # Stroke colour and width come from CSS so the same markup works on ink,
  # ivory, and gold surfaces.
  PATHS = {
    search: '<circle cx="11" cy="11" r="6.5"/><path d="M16 16l4.5 4.5"/>',
    menu: '<path d="M3 6h18M3 12h18M3 18h18"/>',
    close: '<path d="M5 5l14 14M19 5L5 19"/>',
    heart: '<path d="M12 20.3l-7.1-7a4.6 4.6 0 0 1 0-6.5 4.6 4.6 0 0 1 6.5 0l.6.6.6-.6a4.6 4.6 0 0 1 6.5 0 4.6 4.6 0 0 1 0 6.5z"/>',
    diamond: '<path d="M7.5 3h9l4.5 6-9 12L3 9z"/><path d="M3 9h18M7.5 3L5.4 9M16.5 3l2.1 6M9.6 9L12 21M14.4 9L12 21"/>',
    sparkle: '<path d="M12 3l1.9 5.6L19.5 10l-5.6 1.9L12 17.5l-1.9-5.6L4.5 10l5.6-1.4z"/>',
    whatsapp: '<path d="M20.5 11.6a8.5 8.5 0 0 1-12.6 7.4L3.5 20.5l1.6-4.3A8.5 8.5 0 1 1 20.5 11.6z"/><path d="M8.9 8.4c.2-.5.4-.5.7-.5h.5c.2 0 .4 0 .6.5l.8 1.8c.1.3 0 .5-.1.7l-.4.5c-.1.2-.3.4-.1.7a6 6 0 0 0 2.9 2.5c.3.1.5 0 .7-.1l.5-.6c.2-.2.4-.2.6-.1l1.7.8c.3.1.4.3.4.5a1.8 1.8 0 0 1-1.7 1.6c-1 0-3.2-.7-5-2.5s-2.5-3.9-2.5-5a2 2 0 0 1 .4-1.3z"/>',
    instagram: '<rect x="3.5" y="3.5" width="17" height="17" rx="5"/><circle cx="12" cy="12" r="4"/><circle cx="17.2" cy="6.8" r="0.9" fill="currentColor" stroke="none"/>',
    mail: '<rect x="3" y="5.5" width="18" height="13" rx="1.5"/><path d="M3.6 6.4l8.4 6 8.4-6"/>',
    box: '<path d="M3.5 8.5h17v11h-17z"/><path d="M3.5 8.5L5 4.5h14l1.5 4M12 4.5v15M3.5 13h17"/>',
    bag: '<path d="M6.5 8.5h11l-.8 11h-9.4z"/><path d="M9 8.5V7a3 3 0 0 1 6 0v1.5"/>',
    arrow_right: '<path d="M4 12h15M13.5 6.5L20 12l-6.5 5.5"/>'
  }.freeze

  def icon(name, size: nil, **options)
    path = PATHS.fetch(name.to_sym)
    style = "width:#{size};height:#{size}" if size

    tag.svg(
      raw(path),
      viewBox: "0 0 24 24",
      fill: "none",
      stroke: "currentColor",
      "stroke-width": 1.3,
      "stroke-linecap": "round",
      "stroke-linejoin": "round",
      "aria-hidden": "true",
      focusable: "false",
      style: style,
      **options
    )
  end
end
