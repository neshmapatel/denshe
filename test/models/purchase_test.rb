require "test_helper"

class PurchaseTest < ActiveSupport::TestCase
  setup do
    @supplier = Supplier.create!(name: "Mahavir Enterprise")
  end

  test "requires total to equal merchandise plus courier" do
    purchase = Purchase.new(
      supplier: @supplier,
      reference: "MV-LOT-001",
      article_count: 62,
      merchandise_total: 5170,
      courier_charge: 80,
      total_amount: 5000
    )

    refute purchase.valid?
    assert purchase.errors[:total_amount].any?
  end

  test "accepts a lot whose total includes courier" do
    purchase = Purchase.create!(
      supplier: @supplier,
      reference: "MV-LOT-001",
      article_count: 62,
      merchandise_total: 5170,
      courier_charge: 80,
      tax_amount: 0,
      total_amount: 5250
    )

    assert_equal 84.68, purchase.landed_cost_per_article.to_f
  end

  test "accepts a lot whose total includes courier and tax" do
    purchase = Purchase.create!(
      supplier: @supplier,
      reference: "CL-10082",
      article_count: 39,
      merchandise_total: 1350,
      courier_charge: 120,
      tax_amount: 40.50,
      total_amount: 1510.50
    )

    assert purchase.persisted?
  end
end
