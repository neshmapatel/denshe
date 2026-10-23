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
    follow_redirect!
    assert_match "Choose 1 from Earrings", response.body

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
    assert_redirected_to checkout_success_path

    order = Order.order(:id).last
    assert_equal 299, order.subtotal.to_i
    priced = order.order_items.find_by!(name: "Festive pair")
    assert_equal 299, priced.unit_price.to_i
    assert_equal 0, @studs.reload.stock_quantity
    assert_equal 0, @pendant.reload.stock_quantity
    assert_equal 1, @jhumkas.reload.stock_quantity
    assert_equal 1, @left_out.reload.stock_quantity
  end

  test "a look stops once the shopper has chosen the number of pieces it asks for" do
    earrings = Category.find_by!(name: "Earrings")
    pieces = 5.times.map do |index|
      Product.create!(category: earrings, name: "Jhumka #{index + 1}", selling_price: 150 + index, stock_quantity: 1, status: :active)
    end
    combo = Combo.create!(
      name: "Jhumkas",
      price: 339,
      status: :active,
      groups_attributes: [
        { name: "Jhumkas", choose_count: 3, position: 1, selected_product_ids: pieces.map(&:id) }
      ]
    )

    get combo_path(combo.slug)
    assert_response :success
    assert_select "fieldset[data-limit='3']"
    assert_select "input[type=checkbox][data-action='combo-picks#change']", 5
    assert_select "button[data-combo-picks-target='submit']", text: /Take this look/

    group = combo.groups.find_by!(name: "Jhumkas")
    post cart_combos_path, params: { slug: combo.slug, picks: { group.id => pieces.map(&:id) } }
    assert_redirected_to combo_path(combo.slug)
    follow_redirect!
    assert_match "Choose 3 from Jhumkas", response.body

    post cart_combos_path, params: { slug: combo.slug, picks: { group.id => pieces.first(3).map(&:id) } }
    assert_redirected_to cart_path
  end

  test "the landing page opens a look and the catalogue only offers a message" do
    get root_path
    assert_response :success
    assert_select "a.combo-card[href='#{combo_path(@combo.slug)}']", text: /Festive pair/
    assert_select "a.combo-card", text: /Choose the pieces/

    get catalogue_path
    assert_response :success
    assert_select "#looks h3", text: "Festive pair"
    assert_select "#looks .catalogue-look__name", text: "Rose Studs"
    assert_select "#looks .catalogue-look__name", text: "Sun Pendant"
    assert_select "#looks .catalogue-look__photo img", 3
    assert_select "#looks input", count: 0
    assert_select "#looks button", count: 0
    note = CGI.unescape(css_select("#looks a.catalogue-look__whatsapp").first["href"])
    assert_includes note, "I am interested in this look, and I would like to purchase these pieces from it."
    assert_includes note, "Rose Studs"
    assert_includes note, "Sun Pendant"
    assert_includes note, "wa.me/919586488320"
  end
end
