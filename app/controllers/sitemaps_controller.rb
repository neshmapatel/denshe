class SitemapsController < ApplicationController
  def show
    @entries = static_pages + collection_pages + piece_pages
  end

  private

  def static_pages
    [
      entry(root_url, changefreq: "weekly", priority: "1.0"),
      entry(shop_url, changefreq: "daily", priority: "0.9"),
      entry(collections_url, changefreq: "weekly", priority: "0.8"),
      entry(story_url, changefreq: "monthly", priority: "0.6"),
      entry(care_url, changefreq: "monthly", priority: "0.5"),
      entry(contact_url, changefreq: "monthly", priority: "0.5"),
      entry(mystery_box_url, changefreq: "monthly", priority: "0.6")
    ]
  end

  def collection_pages
    Category.ordered.stocked.map do |category|
      entry(collection_url(category.slug), changefreq: "weekly", priority: "0.8")
    end
  end

  def piece_pages
    Product.active.order(:updated_at).map do |product|
      entry(piece_url(product.slug), changefreq: "weekly", priority: "0.7", lastmod: product.updated_at)
    end
  end

  def entry(loc, changefreq:, priority:, lastmod: nil)
    { loc: loc, changefreq: changefreq, priority: priority, lastmod: lastmod }
  end
end
