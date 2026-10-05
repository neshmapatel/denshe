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
    assert_equal 80, order.shipping_amount
    assert_equal 779, order.total
    assert_equal 0, @product.reload.stock_quantity
    assert_equal 1, order.inventory_movements.where(movement_type: :customer_order).count
    assert_not @product.available_for_sale?
  end

  test "waives shipping at the free shipping threshold" do
    @product.update!(selling_price: 999)
    order = checkout.place!(@cart)

    assert_equal 0, order.shipping_amount
    assert_equal 999, order.total
  end

  test "keeps a separate billing address when it differs" do
    order = checkout(billing_same: false, billing_line1: "12 Hill Road", billing_city: "Pune", billing_state: "Maharashtra", billing_pin_code: "411001").place!(@cart)

    assert_equal "Pune", order.billing_address.city
    assert_equal "Mumbai", order.shipping_address.city
  end

  test "an australian order reserves the piece and records the australian price" do
    @product.update!(visible_in_australia: true, selling_price_aud: 49)
    @cart.remove(@product)
    cart = Cart.new({}, market: Market.australia)
    assert_equal :added, cart.add(@product)

    order = checkout(
      phone: "0412 345 678",
      city: "Sydney",
      state: "New South Wales",
      pin_code: "2000"
    ).tap { |form| form.market = Market.australia }.place!(cart)

    assert_predicate order, :persisted?
    assert_equal "AUD", order.currency
    assert_equal "unpaid", order.payment_status
    assert_equal 49, order.total
    assert_equal 0, order.shipping_amount
    assert_equal 49, order.order_items.sole.unit_price
    assert_equal "Australia", order.shipping_address.country
    assert_equal "2000", order.shipping_address.pin_code
    assert_equal "0412345678", order.guest_phone
    assert_equal 0, @product.reload.stock_quantity
  end

  test "australia does not accept a piece that is not offered there" do
    cart = Cart.new({}, market: Market.australia)

    assert_equal :not_offered, cart.add(@product)
    assert_nil checkout.tap { |form| form.market = Market.australia }.place!(cart)
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
