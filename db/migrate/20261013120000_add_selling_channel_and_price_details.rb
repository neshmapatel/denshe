class AddSellingChannelAndPriceDetails < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :channel, :integer, null: false, default: 0
    add_column :orders, :coupon_discount, :decimal, precision: 10, scale: 2, null: false, default: 0
    add_column :orders, :voucher_discount, :decimal, precision: 10, scale: 2, null: false, default: 0
    add_index :orders, :channel

    add_column :order_items, :compare_at_price, :decimal, precision: 10, scale: 2
    add_column :order_items, :discount_amount, :decimal, precision: 10, scale: 2, null: false, default: 0

    change_column_null :customers, :email, true
  end
end
