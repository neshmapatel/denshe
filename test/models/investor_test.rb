require "test_helper"

class InvestorTest < ActiveSupport::TestCase
  test "tracks Neshma as the only current investor" do
    neshma = Investor.create!(name: "Neshma", email: "neshma@denshe.in")
    devanshi = Investor.create!(name: "Devanshi", email: "devanshi@denshe.in")
    supplier = Supplier.create!(name: "Mahavir Enterprise")
    purchase = Purchase.create!(
      supplier: supplier,
      funded_by: neshma,
      reference: "MV-LOT-001",
      merchandise_total: 5170,
      courier_charge: 80,
      tax_amount: 0,
      total_amount: 5250
    )
    Investment.create!(
      investor: neshma,
      purchase: purchase,
      amount: 5250,
      kind: :product_purchase,
      invested_on: Date.new(2026, 9, 20)
    )

    total = Investment.sum(:amount)
    assert_equal 5250, neshma.total_invested
    assert_equal 0, devanshi.total_invested
    assert_equal 100, neshma.share_percent(total)
    assert_equal 0, devanshi.share_percent(total)
    assert_equal neshma, purchase.funded_by
  end
end
