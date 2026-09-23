require "test_helper"

class InventoryReportTest < ActiveSupport::TestCase
  setup do
    @earrings = Category.create!(name: "Earrings", position: 1)
    @rings = Category.create!(name: "Rings", position: 2)
    @mahavir = Supplier.create!(name: "Mahavir Enterprise")
    @celestia = Supplier.create!(name: "Celestia")

    Product.create!(category: @earrings, supplier: @mahavir, name: "Golden Hoops", sku: "R-1", purchase_price: 35, selling_price: 0, stock_quantity: 1)
    Product.create!(category: @earrings, supplier: @celestia, name: "Silver Studs", sku: "R-2", purchase_price: 40, selling_price: 0, stock_quantity: 1)
    Product.create!(category: @earrings, supplier: @celestia, name: "Tiny Hoops", sku: "R-3", purchase_price: 16, selling_price: 0, stock_quantity: 1)
    Product.create!(category: @rings, supplier: @celestia, name: "Adjustable Ring", sku: "R-4", purchase_price: 50, selling_price: 0, stock_quantity: 1)
  end

  test "counts earrings when that category is selected" do
    report = InventoryReport.new(category_id: @earrings.id)

    assert_equal 3, report.totals[:designs]
    assert_equal 3, report.totals[:pieces]
    assert_equal 91, report.totals[:purchase_total]
    assert_equal [ "Earrings" ], report.category_summaries.map { |row| row[:name] }
  end

  test "filters by supplier and purchase price" do
    report = InventoryReport.new(supplier_id: @celestia.id, min_price: 30, max_price: 45)

    assert_equal [ "Silver Studs" ], report.products.map(&:name)
    assert_equal 1, report.category_summaries.find { |row| row[:name] == "Earrings" }[:designs]
  end
end
