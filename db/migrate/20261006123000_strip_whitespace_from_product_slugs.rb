class StripWhitespaceFromProductSlugs < ActiveRecord::Migration[8.1]
  def up
    Product.reset_column_information

    Product.find_each do |product|
      clean = Product.tidy_slug(product.slug)
      next if clean.blank? || clean == product.slug

      candidate = clean
      suffix = 2
      while Product.where.not(id: product.id).exists?(slug: candidate)
        candidate = "#{clean}-#{suffix}"
        suffix += 1
      end

      product.update_columns(slug: candidate, updated_at: Time.current)
    end
  end

  def down
  end
end
