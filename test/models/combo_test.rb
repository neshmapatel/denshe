require "test_helper"

class ComboTest < ActiveSupport::TestCase
  setup do
    category = Category.create!(name: "Earrings", position: 1)
    @studs = Product.create!(category: category, name: "Rose Studs", selling_price: 200, stock_quantity: 1, status: :active)
    @jhumkas = Product.create!(category: category, name: "Pearl Jhumkas", selling_price: 250, stock_quantity: 1, status: :active)
  end

  test "an active combo needs enough pieces in each choice" do
    combo = Combo.new(
      name: "Festive pair",
      price: 299,
      status: :active,
      groups_attributes: [
        { name: "Earrings", choose_count: 2, selected_product_ids: [ @studs.id ] }
      ]
    )

    assert_not combo.valid?
    assert_match(/can pick 2/, combo.errors.full_messages.join)
  end

  test "saving a choice keeps the selected pieces" do
    combo = Combo.create!(
      name: "Festive pair",
      price: 299,
      status: :active,
      groups_attributes: [
        { name: "Earrings", choose_count: 1, selected_product_ids: [ @studs.id, @jhumkas.id ] }
      ]
    )

    assert_equal [ @studs.id, @jhumkas.id ].sort, combo.groups.first.product_ids.sort
  end
end
