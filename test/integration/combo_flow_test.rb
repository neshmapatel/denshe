require "test_helper"

class ComboFlowTest < ActionDispatch::IntegrationTest
  setup do
    earrings = Category.create!(name: "Earrings", position: 1)
    pendants = Category.create!(name: "Chain Pendants", position: 2)
    @studs = Product.create!(category: earrings, name: "Rose Studs", selling_price: 200, stock_quantity: 1, status: :active)
    @jhumkas = Product.create!(category: earrings, name: "Pearl Jhumkas", selling_price: 250, stock_quantity: 1, status: :active)
    @pendant = Product.create!(category: pendants, name: "Sun Pendant", selling_price: 400, stock_quantity: 1, status: :active)
    @left_out = Product.create!(category: pendants, name: "Left Out", selling_price: 300, stock_quantity: 1, status: :active)

    @combo = Combo.create!(
      name: "Festive pair",
      price: 299,
      status: :active,
      short_description: "One pair and one pendant.",
      groups_attributes: [
        { name: "Earrings", choose_count: 1, position: 1, selected_product_ids: [ @studs.id, @jhumkas.id ] },
        { name: "Pendants", choose_count: 1, position: 2, selected_product_ids: [ @pendant.id ] }
      ]
    )
  end

  test "a shopper builds a combo from the pieces the admin set aside" do
    get combos_path
    assert_response :success
    assert_select "h1", "Looks"
    assert_select "a.combo-card", text: /Festive pair/
    assert_select "a.combo-card", text: /₹299/

    get combo_path(@combo.slug)
    assert_response :success
    assert_select "h1", "Festive pair"
    assert_select "button", text: /Take this look/
    assert_select "label.combo-pick", 3
    assert_select ".combo-pick__price", text: "₹200"
    assert_select ".combo-pick__name", text: "Left Out", count: 0

    post cart_combos_path, params: { slug: @combo.slug, picks: {} }
    assert_redirected_to combo_path(@combo.slug)

    get cart_path
    assert_select "h2", text: "Nothing selected yet."

    earring_group = @combo.groups.find_by!(name: "Earrings")
    pendant_group = @combo.groups.find_by!(name: "Pendants")
    post cart_combos_path, params: {
      slug: @combo.slug,
      picks: { earring_group.id => @studs.id, pendant_group.id => @pendant.id }
    }
    assert_redirected_to cart_path
    follow_redirect!
    assert_select "h2", "Festive pair"
    assert_match "Rose Studs", response.body
    assert_match "Sun Pendant", response.body
    assert_match "₹299", response.body
    assert_no_match "₹600", response.body

    assert_difference -> { Order.count }, 1 do
      post checkout_path, params: {
        checkout: {
          name: "Aisha Shah",
          phone: "9876543210",
          email: "aisha@example.com",
          line1: "14 Sea Face",
          city: "Mumbai",
          state: "Maharashtra",
          pin_code: "400001",
          billing_same: "1"
        }
      }
    end
    assert_redirected_to checkout_payment_path

    order = Order.order(:id).last
    assert_equal 299, order.subtotal.to_i
    priced = order.order_items.find_by!(name: "Festive pair")
    assert_equal 299, priced.unit_price.to_i
    assert_equal 0, @studs.reload.stock_quantity
    assert_equal 0, @pendant.reload.stock_quantity
    assert_equal 1, @jhumkas.reload.stock_quantity
    assert_equal 1, @left_out.reload.stock_quantity
  end
end
