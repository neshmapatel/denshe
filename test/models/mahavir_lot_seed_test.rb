require "test_helper"

class MahavirLotSeedTest < ActiveSupport::TestCase
  test "creates 62 unique Mahavir pieces whose costs match the lot" do
    load Rails.root.join("db/seeds.rb")
    load Rails.root.join("db/seeds.rb")

    supplier = Supplier.find_by!(name: "Mahavir Enterprise")
    purchase = Purchase.find_by!(reference: "MV-LOT-001")

    assert_equal "8169946997", supplier.phone
    assert_equal "Malad", supplier.area
    assert_equal "Mumbai", supplier.city
    assert_equal 62, purchase.article_count
    assert_equal 62, purchase.products.count
    assert_equal 62, Product.where(supplier: supplier).count
    assert_equal 1, Product.where(sku: "MV-KDA-001").count
    assert_equal 5170, purchase.products.sum(:purchase_price)
    assert_equal 80, purchase.courier_charge
    assert_equal 5250, purchase.total_amount
    assert_equal 11, purchase.products.joins(:category).where(categories: { name: "Kadas" }).count
    assert_equal 4, purchase.products.joins(:category).where(categories: { name: "Bracelets" }).count
    assert_equal 5, purchase.products.joins(:category).where(categories: { name: "Combo" }).count
    assert_equal 3, purchase.products.joins(:category).where(categories: { name: "Handchains" }).count
    assert_equal 29, purchase.products.joins(:category).where(categories: { name: "Chain Pendants" }).count
    assert_equal 10, purchase.products.joins(:category).where(categories: { name: "Earrings" }).count
    assert purchase.products.all? { |product| product.stock_quantity == 1 }
    assert_equal "Neshma", purchase.funded_by.name
  end
end
