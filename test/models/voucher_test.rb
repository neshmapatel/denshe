require "test_helper"

class VoucherTest < ActiveSupport::TestCase
  test "picks the largest offer the amount qualifies for" do
    Voucher.create!(name: "Small", minimum_spend: 500, discount_amount: 50)
    best = Voucher.create!(name: "Large", minimum_spend: 1000, discount_amount: 150)
    Voucher.create!(name: "Later", minimum_spend: 100, discount_amount: 400, starts_on: Date.current + 2, ends_on: Date.current + 3)

    assert_equal best, Voucher.for_subtotal(1000)
    assert_nil Voucher.for_subtotal(499)
  end

  test "a turned off offer is not applied" do
    Voucher.create!(name: "Paused", minimum_spend: 100, discount_amount: 20, active: false)

    assert_nil Voucher.for_subtotal(500)
  end
end