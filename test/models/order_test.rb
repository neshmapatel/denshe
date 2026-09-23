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

  test "searches orders by number, guest details, or customer" do
    customer = Customer.create!(name: "Meera Shah", email: "meera@example.com", phone: "9876543210")
    order = Order.create!(
      customer: customer,
      guest_name: "Aisha",
      guest_email: "aisha@example.com",
      subtotal: 599,
      total: 599
    )
    other = Order.create!(guest_name: "Riya", guest_email: "riya@example.com", subtotal: 799, total: 799)

    assert_includes Order.search(order.number), order
    assert_includes Order.search("meera"), order
    assert_includes Order.search("aisha@example.com"), order
    assert_not_includes Order.search("meera"), other
  end
end
