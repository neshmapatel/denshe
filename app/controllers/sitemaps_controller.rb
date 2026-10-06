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
      entry(catalogue_url, changefreq: "daily", priority: "0.7"),
      entry(story_url, changefreq: "monthly", priority: "0.6"),
      entry(care_url, changefreq: "monthly", priority: "0.5"),
      entry(contact_url, changefreq: "monthly", priority: "0.5"),
      entry(shipping_returns_url, changefreq: "monthly", priority: "0.4"),
      entry(mystery_box_url, changefreq: "monthly", priority: "0.6")
    ]
  end

  def collection_pages
    collection_line_pages + category_pages
  end

  def collection_line_pages
    CollectionLine.all.filter_map do |line|
      next if line.western? && !Product.catalogue.western.exists?

      entry(collection_url(line.slug), changefreq: "weekly", priority: "0.8")
    end
  end

  def category_pages
    Category.ordered.stocked.map do |category|
      entry(collection_url(category.slug), changefreq: "weekly", priority: "0.8")
    end
  end

  def piece_pages
    Product.active.order(:updated_at).map do |product|
      entry(piece_url(product.public_slug), changefreq: "weekly", priority: "0.7", lastmod: product.updated_at)
    end
  end

  def entry(loc, changefreq:, priority:, lastmod: nil)
    { loc: loc, changefreq: changefreq, priority: priority, lastmod: lastmod }
  end
end
