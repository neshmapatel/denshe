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
    assert_select "select[name='order[channel]'] option[selected]", text: "Offline"
    assert_select "input[name='order[total]']"
    assert_select "input[name='order[amount_paid]']"
    assert_select "label", text: "Total"
    assert_select "label", text: "Amount paid"
    assert_select "input[name='order[coupon_code]']"
    assert_select "input[name='order[voucher_name]']"
  end

  test "an order can be saved for a new customer and marked paid in cash or as a gift" do
    get new_admin_voucher_path
    assert_response :success
    assert_select "input[name='voucher[minimum_spend]']"
    assert_select "input[name='voucher[percent]']"
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
    assert_select "a[href*='wa.me/919123456780']", text: "Invoice on WhatsApp"
    assert_select "a[href='#{invoice_path(order.invoice_token, format: :pdf)}']", text: "Invoice PDF"
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

  test "an order page can change the price of a piece" do
    category = Category.create!(name: "Earrings", position: 1)
    product = Product.create!(
      category: category,
      name: "Aurelia Hoops",
      selling_price: 499,
      compare_at_price: 699,
      purchase_price: 180,
      stock_quantity: 1,
      status: :active
    )
    order = Order.create!(
      guest_name: "Aisha Shah",
      guest_email: "aisha@example.com",
      guest_phone: "9876543210",
      subtotal: 499,
      shipping_amount: 80,
      total: 579,
      channel: :offline
    )
    item = order.order_items.create!(
      product: product,
      name: product.name,
      quantity: 1,
      unit_price: 499,
      compare_at_price: 699,
      item_type: :catalogue
    )

    get edit_admin_order_path(order)
    assert_response :success
    assert_select "input[name='order[order_items_attributes][0][unit_price]']" do |inputs|
      assert_equal "499.0", inputs.first["value"]
    end
    assert_select "input[name='order[coupon_discount]']"
    assert_select "input[name='order[voucher_discount]']"

    patch admin_order_path(order), params: {
      order: {
        channel: "offline",
        subtotal: "450",
        shipping_amount: "80",
        discount: "0",
        coupon_code: "FESTIVE",
        coupon_discount: "0",
        voucher_name: "Navratri",
        voucher_discount: "0",
        total: "530",
        amount_paid: "440",
        order_items_attributes: {
          "0" => { id: item.id, quantity: 1, unit_price: "450", compare_at_price: "699" }
        }
      }
    }
    follow_redirect!
    assert_equal admin_order_path(order), path

    order.reload
    assert_equal "offline", order.channel
    assert_equal "FESTIVE", order.coupon_code
    assert_equal "Navratri", order.voucher_name
    assert_equal 450, order.order_items.sole.unit_price
    assert_equal 249, order.order_items.sole.discount_amount
    assert_equal 530, order.total
    assert_equal 440, order.amount_paid

    get invoice_path(order.invoice_token, format: :pdf)
    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert response.body.start_with?("%PDF")
    invoice = response.body.b.scan(/<([0-9A-Fa-f]+)>/).flatten.map { |hex| [hex].pack("H*") }.join
    assert_includes invoice, "Aurelia Hoops"
    assert_includes invoice, "Rs 440"
    assert_includes invoice, "Rs 530"
    assert_includes invoice, "Amount paid"

    get invoice_path("not-a-real-invoice", format: :pdf)
    assert_response :not_found

    get admin_order_path(order)
    assert_match "Sold through", response.body
    assert_match "Amount paid", response.body
    assert_match "Offline", response.body
    assert_match "FESTIVE", response.body
    assert_match "Navratri", response.body
    assert_match "Aurelia Hoops", response.body
  end
end