require "test_helper"

class CouponFlowTest < ActionDispatch::IntegrationTest
  setup do
    category = Category.create!(name: "Earrings", position: 1)
    @product = Product.create!(category: category, name: "Rose Studs", selling_price: 500, stock_quantity: 1, status: :active)
    Coupon.create!(code: "festive10", percent: 10, active: true)
  end

  test "a shopper applies a code and pays the reduced total" do
    post cart_items_path, params: { slug: @product.slug }

    post cart_coupon_path, params: { code: "festive10" }
    follow_redirect!
    assert_response :success
    assert_match "FESTIVE10 · 10% off", response.body
    assert_match "₹50", response.body
    assert_match "₹530", response.body

    post checkout_path, params: {
      checkout: {
        name: "Aisha Shah",
        phone: "9876543210",
        email: "aisha@example.com",
        line1: "14 Sea Face",
        city: "Mumbai",
        state: "Maharashtra",
        pin_code: "400001",
        billing_same: "1"
      }
    }
    assert_redirected_to checkout_payment_path

    order = Order.order(:id).last
    assert_equal "FESTIVE10", order.coupon_code
    assert_equal 50, order.discount.to_i
    assert_equal 80, order.shipping_amount.to_i
    assert_equal 530, order.total.to_i

    follow_redirect!
    assert_match "Offer · FESTIVE10", response.body
    assert_match "₹530", response.body
  end

  test "an unknown code is refused" do
    post cart_items_path, params: { slug: @product.slug }
    post cart_coupon_path, params: { code: "nope" }
    follow_redirect!

    assert_match "That code is not available.", response.body
    assert_no_match "Offer", response.body
  end
end