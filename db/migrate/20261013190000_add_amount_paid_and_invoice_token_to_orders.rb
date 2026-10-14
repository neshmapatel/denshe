class AddAmountPaidAndInvoiceTokenToOrders < ActiveRecord::Migration[8.1]
  def up
    add_column :orders, :amount_paid, :decimal, precision: 10, scale: 2
    add_column :orders, :invoice_token, :string

    Order.reset_column_information
    Order.find_each do |order|
      paid = if order.payment_method == "owner_gift"
        0
      elsif order.payment_paid?
        collected = order.payments.paid.sum(:amount)
        collected.to_d.zero? ? order.total : collected
      end
      order.update_columns(invoice_token: SecureRandom.base58(24), amount_paid: paid)
    end

    add_index :orders, :invoice_token, unique: true
  end

  def down
    remove_index :orders, :invoice_token
    remove_column :orders, :invoice_token
    remove_column :orders, :amount_paid
  end
end
