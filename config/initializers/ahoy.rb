class Ahoy::Store < Ahoy::DatabaseStore
  def track_visit(data)
    data[:country] ||= request.headers["CF-IPCountry"].to_s.presence
    data[:city] ||= request.headers["CF-IPCity"].to_s.presence
    data[:region] ||= request.headers["CF-Region"].to_s.presence
    super(data)
  end
end

Ahoy.api = false
Ahoy.server_side_visits = true
Ahoy.track_bots = false
Ahoy.mask_ips = true
Ahoy.cookie_options = { same_site: :lax }

Ahoy.exclude_method = lambda do |_controller, request|
  request.path.start_with?("/up", "/admin", "/rails", "/assets")
end

Ahoy.geocode = false
