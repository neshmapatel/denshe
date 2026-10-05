class AddAustraliaPricing < ActiveRecord::Migration[8.1]
  def change
    change_table :products, bulk: true do |t|
      t.boolean :visible_in_australia, default: false, null: false
      t.decimal :selling_price_aud, precision: 10, scale: 2
      t.decimal :compare_at_price_aud, precision: 10, scale: 2
      t.index :visible_in_australia
    end

    add_column :orders, :currency, :string, default: "INR", null: false
  end
end