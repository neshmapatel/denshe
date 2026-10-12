require "test_helper"

class AdminOrderDeskTest < ActionDispatch::IntegrationTest
  setup do
    @admin = AdminUser.create!(
      name: "Neshma",
      email: "neshma-desk@denshe.in",
      password: "denshe-admin-123",
      password_confirmation: "denshe-admin-123",
      role: :super_admin
    )
    post admin_user_session_path, params: {
      admin_user: { email: @admin.email, password: "denshe-admin-123" }
    }
  end

  test "a customer page can start an order for that customer" do
    customer = Customer.create!(name: "Aisha Shah", email: "aisha@example.com", phone: "9876543210")

    get admin_customer_path(customer)
    assert_select "a[href='#{new_admin_order_path(customer_id: customer.id)}']", text: "New order"

    get new_admin_order_path(customer_id: customer.id)
    assert_response :success
    assert_select "option[selected][value='#{customer.id}']", text: "Aisha Shah"
    assert_select "input[name='order[new_customer_name]']"
  end

  test "an order can be saved for a new customer and marked paid in cash or as a gift" do
    get new_admin_voucher_path
    assert_response :success
    assert_select "input[name='voucher[minimum_spend]']"
    assert_select "input[name='voucher[active]']"
    assert_select "label", text: "Activate on"
    assert_select "label", text: "Deactivate on"

    assert_difference -> { Customer.count }, 1 do
      post admin_orders_path, params: {
        order: {
          new_customer_name: "Riya Shah",
          new_customer_email: "riya@example.com",
          new_customer_phone: "9123456780",
          subtotal: 500,
          total: 500,
          status: "pending",
          payment_status: "unpaid"
        }
      }
    end
    order = Order.order(:id).last
    assert_equal "Riya Shah", order.customer.name

    get admin_order_path(order)
    assert_select "a[href='#{collect_cash_admin_order_path(order)}']", text: "Collected in cash"
    assert_select "a[href='#{gift_by_owner_admin_order_path(order)}']", text: "Gifted by the owner"

    post collect_cash_admin_order_path(order)
    follow_redirect!
    assert_match "Collected in cash and marked as paid.", response.body
    assert order.reload.payment_paid?
    assert_equal "cash", order.payment_method

    gift = Order.create!(subtotal: 200, total: 200)
    post gift_by_owner_admin_order_path(gift)
    follow_redirect!
    assert_match "Marked as paid. Gifted by the owner.", response.body
    assert_equal "owner_gift", gift.reload.payment_method
  end
end