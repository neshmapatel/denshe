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

  test "guest details open a customer once, and a new piece price rewrites the order price" do
    order = Order.create!(
      guest_name: "Meera Shah",
      guest_email: "meera@example.com",
      guest_phone: "9988776655",
      subtotal: 499,
      shipping_amount: 80,
      total: 579,
      channel: :offline
    )
    item = order.order_items.create!(
      name: "Aurelia Hoops",
      quantity: 1,
      unit_price: 499,
      compare_at_price: 699
    )

    again = Order.create!(
      guest_name: "Meera Shah",
      guest_email: "meera@example.com",
      guest_phone: "9988776655",
      subtotal: 100,
      total: 100
    )

    assert_equal order.customer_id, again.customer_id
    assert_equal 1, Customer.where(email: "meera@example.com").count
    assert_equal 200, item.reload.discount_amount

    order.update!(order_items_attributes: [ { id: item.id, unit_price: 450 } ])

    assert_equal 450, order.subtotal
    assert_equal 530, order.total
    assert_equal 249, item.reload.discount_amount
    assert order.offline?
    assert again.website?
  end

  test "existing orders gain a customer from the name and mobile, and the invoice lists the piece" do
    order = Order.create!(
      guest_name: "Aisha Shah",
      guest_phone: "9876543210",
      guest_email: "aisha@example.com",
      subtotal: 499,
      total: 499,
      channel: :offline
    )
    order.order_items.create!(
      name: "Aurelia Hoops",
      quantity: 1,
      unit_price: 499,
      compare_at_price: 699
    )
    order.update_column(:customer_id, nil)
    same_phone = Order.create!(guest_name: "Aisha S", guest_phone: "98765 43210", subtotal: 100, total: 100)
    same_phone.update_column(:customer_id, nil)

    assert_equal 2, Order.backfill_customers!

    order.reload
    assert_equal "Aisha Shah", order.customer.name
    assert_equal "9876543210", order.customer.phone
    assert_equal order.customer_id, same_phone.reload.customer_id

    order.update!(
      subtotal: 499,
      discount: 19,
      coupon_code: "FESTIVE",
      coupon_discount: 19,
      total: 480,
      amount_paid: 440
    )
    order.collect_cash!
    text = order.invoice_text
    assert_match "Total ₹480", text
    assert_match "Amount paid ₹440", text
    assert_match "/invoices/#{order.invoice_token}.pdf", text
    assert_match "https://wa.me/919876543210?text=", order.invoice_whatsapp_url
    assert_equal 440, order.payments.paid.sole.amount

    pdf = pdf_text(order.invoice_pdf)
    assert_includes pdf, "Aurelia Hoops"
    assert_includes pdf, "Rs 499"
    assert_includes pdf, "Rs 200"
    assert_includes pdf, "Coupon FESTIVE"
    assert_includes pdf, "Total"
    assert_includes pdf, "Amount paid"
    assert_includes pdf, "Rs 480"
    assert_includes pdf, "Rs 440"
    assert_includes pdf, "Balance"
    assert_includes pdf, "Rs 40"
  end

  def pdf_text(pdf)
    pdf.b.scan(/<([0-9A-Fa-f]+)>/).flatten.map { |hex| [hex].pack("H*") }.join
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