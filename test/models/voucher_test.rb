require "test_helper"

class VoucherTest < ActiveSupport::TestCase
  test "picks the largest offer the amount qualifies for" do
    Voucher.create!(name: "Small", minimum_spend: 500, discount_amount: 50)
    best = Voucher.create!(name: "Large", minimum_spend: 1000, discount_amount: 150)
    Voucher.create!(name: "Later", minimum_spend: 100, discount_amount: 400, starts_on: Date.current + 2, ends_on: Date.current + 3)

    assert_equal best, Voucher.for_subtotal(1000)
    assert_nil Voucher.for_subtotal(499)
  end

  test "a percent offer is taken off the pieces once the amount is reached" do
    offer = Voucher.create!(name: "Above 599", minimum_spend: 599, percent: 5, discount_amount: 0)

    assert_equal 0, offer.discount_for(520)
    assert_equal BigDecimal("29.95"), offer.discount_for(599)
    assert_equal offer, Voucher.for_subtotal(599)
    assert_nil Voucher.for_subtotal(520)
  end

  test "the next offer is the nearest amount the bag has not reached" do
    near = Voucher.create!(name: "Above 599", minimum_spend: 599, percent: 5, discount_amount: 0)
    Voucher.create!(name: "Above 999", minimum_spend: 999, percent: 10, discount_amount: 0)

    assert_equal near, Voucher.next_above(520)
    assert_equal 79, near.minimum_spend - 520
    assert_nil Voucher.next_above(999)
  end

  test "a turned off offer is not applied" do
    Voucher.create!(name: "Paused", minimum_spend: 100, discount_amount: 20, active: false)

    assert_nil Voucher.for_subtotal(500)
  end
end