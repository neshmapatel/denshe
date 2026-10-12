class AddCouponUsesAndVouchers < ActiveRecord::Migration[8.1]
  def change
    add_column :coupons, :uses_per_customer, :integer, null: false, default: 1

    create_table :vouchers do |t|
      t.string :name, null: false
      t.decimal :minimum_spend, precision: 10, scale: 2, null: false, default: 0
      t.decimal :discount_amount, precision: 10, scale: 2, null: false
      t.boolean :active, null: false, default: true
      t.date :starts_on
      t.date :ends_on
      t.timestamps
    end

    add_reference :orders, :voucher, foreign_key: { on_delete: :nullify }
    add_column :orders, :voucher_name, :string
  end
end