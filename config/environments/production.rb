require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Turn on fragment caching in view templates.
  config.action_controller.perform_caching = true

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Heroku dyno disk is wiped on restart. Use R2 when credentials exist so product
  # photos survive deploys. ACTIVE_STORAGE_SERVICE still wins if set explicitly.
  config.active_storage.service =
    if ENV["ACTIVE_STORAGE_SERVICE"].present?
      ENV["ACTIVE_STORAGE_SERVICE"].to_sym
    elsif ENV["CLOUDFLARE_R2_ACCESS_KEY_ID"].present?
      :cloudflare_r2
    else
      :local
    end
  # Safari shows a broken image when the photo is a redirect to R2. Serve it from this site.
  config.active_storage.resolve_model_to_route = :rails_storage_proxy

  # Heroku terminates SSL at the router. Without this, Active Storage signs http://
  # disk URLs and the browser blocks them on the https admin.
  config.assume_ssl = true
  config.force_ssl = true
  config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [ :request_id ]
  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)

  # Change to "debug" to log everything (including potentially personally-identifiable information!).
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  config.cache_store = :solid_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }

  app_host = ENV.fetch("APP_HOST", "denshe.shop")
  url_options = { host: app_host, protocol: "https" }
  config.action_controller.default_url_options = url_options
  config.action_mailer.default_url_options = url_options
  Rails.application.routes.default_url_options = url_options

  # Outgoing mail. Set SMTP_* in the host env (Gmail app password, Resend SMTP, etc.).
  if ENV["SMTP_ADDRESS"].present?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.raise_delivery_errors = true
    config.action_mailer.perform_deliveries = true
    smtp_port = ENV.fetch("SMTP_PORT", "587").to_i
    config.action_mailer.smtp_settings = {
      address: ENV.fetch("SMTP_ADDRESS"),
      port: smtp_port,
      user_name: ENV["SMTP_USERNAME"],
      password: ENV["SMTP_PASSWORD"],
      authentication: ENV.fetch("SMTP_AUTHENTICATION", "plain").to_sym,
      enable_starttls_auto: ActiveModel::Type::Boolean.new.cast(ENV.fetch("SMTP_ENABLE_STARTTLS_AUTO", "true")),
      # Gmail on 465 expects implicit TLS instead of STARTTLS.
      tls: ActiveModel::Type::Boolean.new.cast(ENV.fetch("SMTP_TLS", (smtp_port == 465).to_s)),
      open_timeout: ENV.fetch("SMTP_OPEN_TIMEOUT", "30").to_i,
      read_timeout: ENV.fetch("SMTP_READ_TIMEOUT", "60").to_i,
      domain: ENV.fetch("SMTP_DOMAIN", app_host)
    }.compact
  end

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [ :id ]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",     # Allow requests from example.com
  #   /.*\.example\.com/ # Allow requests from subdomains like `www.example.com`
  # ]
  #
  # Skip DNS rebinding protection for the default health check endpoint.
  # config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
