require "test_helper"

class CheckoutTest < ActiveSupport::TestCase
  setup do
    @category = Category.create!(name: "Rings", position: 1)
    @product = Product.create!(
      category: @category,
      name: "Aurelia Hoops",
      selling_price: 699,
      purchase_price: 180,
      stock_quantity: 1,
      status: :active
    )
    @session = {}
    @cart = Cart.new(@session)
    @cart.add(@product)
  end

  test "records an unpaid order with shipping and billing addresses" do
    order = checkout.place!(@cart)

    assert_predicate order, :persisted?
    assert_equal "unpaid", order.payment_status
    assert_equal "pending", order.status
    assert_equal "Aisha Shah", order.guest_name
    assert_equal "400001", order.shipping_address.pin_code
    assert_equal order.shipping_address, order.billing_address
    assert_equal 1, order.order_items.count
    assert_equal 699, order.total
    assert_equal 1, @product.reload.stock_quantity
  end

  test "keeps a separate billing address when it differs" do
    order = checkout(billing_same: false, billing_line1: "12 Hill Road", billing_city: "Pune", billing_state: "Maharashtra", billing_pin_code: "411001").place!(@cart)

    assert_equal "Pune", order.billing_address.city
    assert_equal "Mumbai", order.shipping_address.city
  end

  test "rejects a checkout without a name or a valid PIN" do
    form = checkout(name: "", pin_code: "12")

    assert_nil form.place!(@cart)
    assert_includes form.errors[:name], "can't be blank"
    assert_includes form.errors[:pin_code], "must be a 6-digit PIN code"
    assert_equal 0, Order.count
  end

  private

  def checkout(**overrides)
    Checkout.new({
      name: "Aisha Shah",
      phone: "9876543210",
      email: "aisha@example.com",
      line1: "14 Sea Face",
      city: "Mumbai",
      state: "Maharashtra",
      pin_code: "400001",
      billing_same: true
    }.merge(overrides))
  end
end
