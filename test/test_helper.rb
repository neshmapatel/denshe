ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "base64"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    # Fixtures are opt-in per test so empty YAML files do not fail new models.
    # fixtures :all

    def attach_product_image(product, filename)
      product.images.attach(
        io: StringIO.new(tiny_png_bytes),
        filename: filename,
        content_type: "image/png"
      )
      product.images.attachments.reload.last
    end

    def tiny_png_bytes
      Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==")
    end
  end
end
