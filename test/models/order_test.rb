require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "assigns a DeNshe order number after create" do
    order = Order.create!(
      guest_name: "Aisha",
      guest_email: "aisha@example.com",
      subtotal: 599,
      total: 599
    )

    assert_match(/\ADN\d{4}\z/, order.reload.number)
    assert_equal "Aisha", order.customer_display_name
  end
end
