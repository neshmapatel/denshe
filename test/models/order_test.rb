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

  test "reserves catalogue stock once when the order is placed" do
    category = Category.create!(name: "Earrings", position: 1)
    product = Product.create!(
      category: category,
      name: "Aurelia Hoops",
      selling_price: 699,
      stock_quantity: 1,
      status: :active
    )
    order = Order.create!(guest_name: "Aisha", subtotal: 699, total: 699)
    order.order_items.create!(
      product: product,
      name: product.name,
      sku: product.sku,
      quantity: 1,
      unit_price: 699,
      item_type: :catalogue
    )

    order.reserve_catalogue_stock!

    assert_equal 0, product.reload.stock_quantity
    assert_equal 1, order.inventory_movements.where(movement_type: :customer_order).count
    assert_not product.available_for_sale?

    order.capture_payment!(gateway_payment_id: "pay_test")
    assert_equal 0, product.reload.stock_quantity
    assert_equal 1, order.inventory_movements.where(movement_type: :customer_order).count
  end
end
