class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_gateways do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :payment_gateways, :code, unique: true

    create_table :payments do |t|
      t.references :order, null: false, foreign_key: true
      t.references :payment_gateway, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :currency, null: false, default: "INR"
      t.integer :status, null: false, default: 0
      t.string :gateway_order_id
      t.string :gateway_payment_id
      t.string :error_code
      t.text :error_message
      t.string :error_source
      t.string :error_step
      t.string :error_reason
      t.timestamps
    end
    add_index :payments, :gateway_order_id
    add_index :payments, :gateway_payment_id
    add_index :payments, :status
  end
end