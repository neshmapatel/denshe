require "test_helper"

class CartTest < ActiveSupport::TestCase
  setup do
    category = Category.create!(name: "Earrings", position: 1)
    @product = Product.create!(
      category: category,
      name: "Aurelia Hoops",
      selling_price: 699,
      stock_quantity: 1,
      status: :active
    )
  end

  test "a second cart cannot take a piece another shopper is holding" do
    first = Cart.new({})
    second = Cart.new({})

    assert_equal :added, first.add(@product)
    assert_equal :held, second.add(@product)
    assert_equal 1, CartHold.where(product: @product).sum(:quantity)
    assert_not second.include?(@product)
  end

  test "a hold lets go after it goes quiet" do
    first = Cart.new({})
    assert_equal :added, first.add(@product)

    travel CartHold::HOLD_FOR + 1.minute do
      second = Cart.new({})
      assert_equal :added, second.add(@product)
      assert second.include?(@product)
    end
  end

  test "removing a piece frees it for someone else" do
    first = Cart.new({})
    first.add(@product)
    first.remove(@product)

    second = Cart.new({})
    assert_equal :added, second.add(@product)
  end
end