module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :generate_slug, if: -> { slug.blank? && name.present? }
    validates :slug, presence: true, uniqueness: true
  end

  private

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
