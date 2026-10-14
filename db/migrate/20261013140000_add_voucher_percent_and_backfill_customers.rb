class AddVoucherPercentAndBackfillCustomers < ActiveRecord::Migration[8.1]
  def up
    add_column :vouchers, :percent, :decimal, precision: 5, scale: 2

    Order.reset_column_information
    Customer.reset_column_information
    Order.backfill_customers!
  end

  def down
    remove_column :vouchers, :percent
  end
end