class AddCustomerToCoupons < ActiveRecord::Migration[8.1]
  def change
    add_reference :coupons, :customer, foreign_key: true
  end
end