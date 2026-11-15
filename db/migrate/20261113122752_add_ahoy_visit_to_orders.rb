class AddAhoyVisitToOrders < ActiveRecord::Migration[8.1]
  def change
    add_reference :orders, :ahoy_visit, null: true, foreign_key: { to_table: :ahoy_visits }, type: :bigint
  end
end
