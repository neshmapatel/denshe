class AddDiscountPercentToProducts < ActiveRecord::Migration[8.1]
  def up
    add_column :products, :discount_percent, :decimal, precision: 5, scale: 2, default: 0, null: false
    add_column :products, :discount_percent_aud, :decimal, precision: 5, scale: 2, default: 0, null: false

    # One pass per currency so existing marked prices already show their percent.
    execute <<~SQL.squish
      UPDATE products
      SET discount_percent = ROUND(((compare_at_price - selling_price) / compare_at_price) * 100, 2)
      WHERE compare_at_price > selling_price
    SQL
    execute <<~SQL.squish
      UPDATE products
      SET discount_percent_aud = ROUND(((compare_at_price_aud - selling_price_aud) / compare_at_price_aud) * 100, 2)
      WHERE compare_at_price_aud > selling_price_aud
    SQL
  end

  def down
    remove_column :products, :discount_percent
    remove_column :products, :discount_percent_aud
  end
end
