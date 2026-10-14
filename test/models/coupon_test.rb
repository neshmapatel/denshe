require "test_helper"

class CouponTest < ActiveSupport::TestCase
  test "stores the code in uppercase and prices a percent off" do
    coupon = Coupon.create!(code: " festive10 ", percent: 10)

    assert_equal "FESTIVE10", coupon.code
    assert_equal "10%", coupon.percent_label
    assert_equal BigDecimal("69.9"), coupon.discount_for(699)
    assert_equal coupon, Coupon.redeemable("festive10")
  end

  test "a code is valid through its last day and refused after that" do
    open_ended = Coupon.create!(code: "OPEN", percent: 10)
    today = Coupon.create!(code: "TODAY", percent: 10, valid_until: Date.current)
    Coupon.create!(code: "YESTERDAY", percent: 10, valid_until: Date.current - 1)

    assert_equal open_ended, Coupon.redeemable("open")
    assert_equal today, Coupon.redeemable("today")
    assert_nil Coupon.redeemable("yesterday")
  end

  test "an inactive code cannot be redeemed" do
    Coupon.create!(code: "PAUSE", percent: 15, active: false)

    assert_nil Coupon.redeemable("pause")
  end

  test "counts one shopper by phone or email and stops at the limit" do
    coupon = Coupon.create!(code: "ONCE", percent: 10, uses_per_customer: 1)
    order = Order.create!(guest_phone: "9876543210", guest_email: "aisha@example.com", coupon: coupon, coupon_code: "ONCE", subtotal: 500, total: 500)

    assert_not coupon.available_to?(phone: "+91 98765 43210", email: nil)
    assert_not coupon.available_to?(phone: nil, email: "AISHA@example.com")
    assert coupon.available_to?(phone: "9000000000", email: "other@example.com")

    order.update!(status: :cancelled)
    assert coupon.available_to?(phone: "9876543210", email: "aisha@example.com")
  end

  test "a code reserved for one customer matches that phone or email" do
    customer = Customer.create!(name: "Aisha Shah", email: "aisha@example.com", phone: "9876543210")
    coupon = Coupon.create!(code: "AISHA10", percent: 10, customer: customer)

    assert coupon.for_customer?(phone: "+91 98765 43210", email: nil)
    assert coupon.for_customer?(phone: nil, email: "AISHA@example.com")
    assert_not coupon.for_customer?(phone: "9000000000", email: "other@example.com")

    open_code = Coupon.create!(code: "OPEN10", percent: 10)
    assert open_code.for_customer?(phone: "9000000000", email: nil)
  end

  test "rejects a blank code and a percent above 100" do
    coupon = Coupon.new(code: "10% off", percent: 120)

    assert_not coupon.valid?
    assert_includes coupon.errors[:code], "uses letters, numbers, and hyphens"
    assert_includes coupon.errors[:percent], "must be less than or equal to 100"
  end
end