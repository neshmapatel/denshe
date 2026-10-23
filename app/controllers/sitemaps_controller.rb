class SitemapsController < ApplicationController
  def show
    @entries = static_pages + collection_pages + combo_pages + curated_gift_pages + piece_pages
  end

  private

  def static_pages
    [
      entry(root_url, changefreq: "daily", priority: "1.0", lastmod: Time.current.beginning_of_day),
      entry(shop_url, changefreq: "daily", priority: "0.9", lastmod: Product.maximum(:updated_at)),
      entry(collections_url, changefreq: "weekly", priority: "0.8", lastmod: Category.maximum(:updated_at)),
      entry(catalogue_url, changefreq: "daily", priority: "0.8", lastmod: Product.maximum(:updated_at)),
      entry(potlis_and_jars_url, changefreq: "weekly", priority: "0.8", lastmod: CuratedGift.maximum(:updated_at)),
      entry(combos_url, changefreq: "weekly", priority: "0.7", lastmod: Combo.maximum(:updated_at)),
      entry(story_url, changefreq: "monthly", priority: "0.6"),
      entry(care_url, changefreq: "monthly", priority: "0.6"),
      entry(contact_url, changefreq: "monthly", priority: "0.6"),
      entry(shipping_returns_url, changefreq: "monthly", priority: "0.5"),
      entry(privacy_url, changefreq: "monthly", priority: "0.3"),
      entry(terms_url, changefreq: "monthly", priority: "0.3")
    ]
  end

  def collection_pages
    collection_line_pages + category_pages
  end

  def collection_line_pages
    CollectionLine.all.filter_map do |line|
      next if line.western? && !Product.catalogue.western.exists?

      lastmod = Product.catalogue.where(collection_line: line.key).maximum(:updated_at)
      entry(collection_url(line.slug), changefreq: "weekly", priority: "0.8", lastmod: lastmod)
    end
  end

  def category_pages
    Category.ordered.stocked.map do |category|
      lastmod = category.products.active.maximum(:updated_at) || category.updated_at
      entry(collection_url(category.slug), changefreq: "weekly", priority: "0.8", lastmod: lastmod)
    end
  end

  def combo_pages
    combos = Combo.active.ordered.includes(groups: { products: { images_attachments: :blob } }).to_a
    return [] if combos.empty?

    combos.map do |combo|
      images = []
      combo.groups.each do |grp|
        grp.products.each do |p|
          next unless p.images.respond_to?(:attached?) && p.images.attached?

          images << {
            loc: piece_photo_url(p.public_slug),
            title: "#{p.name} · #{combo.name} · DeNshe Jewellery",
            caption: "#{combo.name} curated set: #{p.name}"
          }
        end
      end

      entry(
        combo_url(combo.slug),
        changefreq: "weekly",
        priority: "0.7",
        lastmod: combo.updated_at,
        images: images.first(5)
      )
    end
  end

  def curated_gift_pages
    CuratedGift.seed_defaults! if CuratedGift.none? || CuratedGift.find_by(slug: "noor").present?
    gifts = CuratedGift.active.ordered.to_a
    return [] if gifts.empty?

    gifts.map do |gift|
      images = []
      if gift.images.respond_to?(:attached?) && gift.images.attached? && gift.display_image
        images << {
          loc: rails_blob_url(gift.display_image, host: request.base_url),
          title: "#{gift.product_title.presence || gift.name} · DeNshe Jewellery",
          caption: gift.subtitle.presence || gift.description&.truncate(150)
        }
      end

      entry(
        curated_gift_url(gift.slug),
        changefreq: "weekly",
        priority: "0.8",
        lastmod: gift.updated_at,
        images: images
      )
    end
  end

  def piece_pages
    Product.active.includes(:category, images_attachments: :blob).order(:updated_at).map do |product|
      images = []
      if product.images.respond_to?(:attached?) && product.images.attached?
        images << {
          loc: piece_photo_url(product.public_slug),
          title: "#{product.name} · #{product.category&.name} · DeNshe Jewellery",
          caption: "#{product.name} in #{product.category&.name}. Handcrafted jewellery from DeNshe."
        }
      end

      entry(
        piece_url(product.public_slug),
        changefreq: "weekly",
        priority: "0.7",
        lastmod: product.updated_at,
        images: images
      )
    end
  end

  def entry(loc, changefreq:, priority:, lastmod: nil, images: [])
    { loc: loc, changefreq: changefreq, priority: priority, lastmod: lastmod, images: images }
  end
end
