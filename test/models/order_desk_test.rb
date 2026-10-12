require "test_helper"

class OrderDeskTest < ActiveSupport::TestCase
  test "an order can open a new customer" do
    order = Order.create!(
      new_customer_name: "Riya Shah",
      new_customer_email: "riya@example.com",
      new_customer_phone: "9123456780",
      subtotal: 500,
      total: 500
    )

    assert_equal "Riya Shah", order.customer.name
    assert_equal "riya@example.com", order.guest_email
    assert_equal "9123456780", order.guest_phone
  end

  test "collected cash is paid and a gift is paid without counting as revenue" do
    cash = Order.create!(subtotal: 500, total: 500)
    gift = Order.create!(subtotal: 700, total: 700)

    cash.collect_cash!
    gift.gift_by_owner!

    assert cash.payment_paid?
    assert_equal "paid", cash.status
    assert_equal "Collected in cash", cash.payment_label
    assert_equal 500, cash.payments.sole.amount

    assert gift.payment_paid?
    assert_equal "Gifted by the owner", gift.payment_label
    assert_equal 0, gift.payments.sole.amount
    assert_equal [ cash.id ], Order.revenue_paid.pluck(:id)
  end
end