require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Denshe
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # India-first jewellery storefront and admin.
    config.time_zone = "Mumbai"
    config.active_record.default_timezone = :utc

    config.generators do |g|
      g.orm :active_record, primary_key_type: :bigint
      g.assets false
      g.helper false
      g.test_framework :test_unit, fixture: true
    end
  end
end
