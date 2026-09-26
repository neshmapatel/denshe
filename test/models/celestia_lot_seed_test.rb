require "test_helper"

class CelestiaLotSeedTest < ActiveSupport::TestCase
  test "creates 39 unique Celestia pieces from receipt 10082" do
    load Rails.root.join("db/seeds.rb")
    load Rails.root.join("db/seeds.rb")

    supplier = Supplier.find_by!(name: "Celestia")
    purchase = Purchase.find_by!(reference: "CL-10082")

    assert_equal "6356496735", supplier.phone
    assert_equal "https://www.celestiajewels.com", supplier.website
    assert_equal Date.new(2026, 9, 19), purchase.purchased_on
    assert_equal 39, purchase.article_count
    assert_equal 39, purchase.products.count
    assert_equal 1350, purchase.products.sum(:purchase_price)
    assert_equal 120, purchase.courier_charge
    assert_equal 40.50, purchase.tax_amount
    assert_equal 1510.50, purchase.total_amount
    assert_equal 7, purchase.products.joins(:category).where(categories: { name: "Rings" }).count
    assert_equal 1, purchase.products.joins(:category).where(categories: { name: "Sets" }).count
    assert_equal 1, purchase.products.joins(:category).where(categories: { name: "Combo" }).count
    assert_equal 30, purchase.products.joins(:category).where(categories: { name: "Earrings" }).count
    assert_equal "The Delicate Wish Silver-Tone Fashion Earrings", Product.find_by!(sku: "CL-10082-001").name
    assert purchase.products.all? { |product| product.stock_quantity == 1 }
    assert_equal "Neshma", purchase.funded_by.name
    assert_equal 1510.50, Investment.joins(:investor).where(investors: { name: "Neshma" }, purchase: purchase).sum(:amount)
    assert_equal 0, Investor.find_by!(name: "Devanshi").total_invested
  end
end
