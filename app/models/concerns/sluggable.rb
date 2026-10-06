module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :normalize_slug
    before_validation :generate_slug, if: -> { slug.blank? && name.present? }
    validates :slug, presence: true, uniqueness: true
  end

  class_methods do
    # Addresses are stored without leading or trailing spaces. A space becomes
    # %20 in the link, and Google treats that as a different page.
    def tidy_slug(value)
      value.to_s.strip.gsub(/[[:space:]]+/, "-").squeeze("-").sub(/\A-+/, "").sub(/-+\z/, "")
    end
  end

  def public_slug
    self.class.tidy_slug(slug)
  end

  private

  def normalize_slug
    return if slug.nil?

    self.slug = self.class.tidy_slug(slug).presence
  end

  def generate_slug
    base = name.parameterize
    candidate = base
    suffix = 2

    while self.class.exists?(slug: candidate)
      candidate = "#{base}-#{suffix}"
      suffix += 1
    end

    self.slug = candidate
  end
end
