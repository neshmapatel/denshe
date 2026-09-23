require "test_helper"

class ProductTest < ActiveSupport::TestCase
  setup do
    @category = Category.create!(name: "Earrings", position: 1)
  end

  test "generates a unique slug from the name" do
    product = Product.create!(
      category: @category,
      name: "Aurelia Hoops",
      selling_price: 699,
      purchase_price: 180,
      stock_quantity: 12
    )

    assert_equal "aurelia-hoops", product.slug
    assert_equal 12, product.quantity_purchased
    assert_equal 12, product.stock_quantity
    assert_equal 1, product.inventory_movements.purchase.count
  end

  test "records later stock changes without going negative" do
    product = Product.create!(
      category: @category,
      name: "Pearl Drop Earrings",
      selling_price: 599,
      stock_quantity: 8
    )

    product.adjust_stock!(quantity: -1, movement_type: :customer_order, reason: "Paid order")
    product.adjust_stock!(quantity: 4, movement_type: :purchase, reason: "Supplier restock")

    assert_equal 11, product.reload.stock_quantity
    assert_equal 12, product.quantity_purchased
    assert_equal 1, product.sold_quantity
    assert_raises(ArgumentError) do
      product.adjust_stock!(quantity: -20, movement_type: :damaged, reason: "Too many")
    end
  end

  test "calculates contribution margin from internal cost fields" do
    product = Product.new(
      category: @category,
      name: "Quiet Ring",
      selling_price: 499,
      purchase_price: 120,
      packaging_allocation: 30,
      shipping_allocation: 60
    )

    assert_equal 289, product.contribution_margin
  end

  test "copies supplier from the purchase lot" do
    supplier = Supplier.create!(name: "Mahavir Enterprise")
    purchase = Purchase.create!(
      supplier: supplier,
      reference: "MV-LOT-TEST",
      article_count: 1,
      merchandise_total: 100,
      courier_charge: 0,
      total_amount: 100
    )
    product = Product.create!(
      category: @category,
      purchase: purchase,
      name: "Golden Hoops",
      selling_price: 0,
      purchase_price: 100,
      stock_quantity: 1
    )

    assert_equal supplier, product.supplier
  end
end
