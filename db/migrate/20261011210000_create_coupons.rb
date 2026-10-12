class CreateCoupons < ActiveRecord::Migration[8.1]
  def change
    create_table :coupons do |t|
      t.string :code, null: false
      t.decimal :percent, precision: 5, scale: 2, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :coupons, :code, unique: true

    add_reference :orders, :coupon, foreign_key: { on_delete: :nullify }, null: true
    add_column :orders, :coupon_code, :string
  end
end