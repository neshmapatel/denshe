require "test_helper"

class StorefrontFlowTest < ActionDispatch::IntegrationTest
  setup do
    @category = Category.create!(name: "Earrings", position: 1)
    @product = Product.create!(
      category: @category,
      name: "Aurelia Hoops",
      selling_price: 699,
      purchase_price: 180,
      stock_quantity: 1,
      status: :active,
      colour: "gold",
      material: "Anti-tarnish",
      short_description: "Small hoops for every day.",
      new_arrival: true
    )
  end

  test "public pages tell search engines what they are" do
    get root_url
    assert_select "link[rel=canonical][href=?]", "http://www.example.com/"
    assert_select "meta[name=description]"
    assert_match "Organization", response.body
    assert_select "meta[name=robots][content=?]", "index, follow"

    get piece_path(@product.slug)
    assert_select "link[rel=canonical][href=?]", "http://www.example.com/pieces/#{@product.slug}"
    assert_match "schema.org/InStock", response.body
    assert_match "699.00", response.body

    get cart_path
    assert_select "meta[name=robots][content=?]", "noindex, follow"

    get sitemap_path
    assert_response :success
    assert_match piece_url(@product.slug), response.body
    assert_no_match %r{/cart}, response.body
    assert_no_match %r{/admin}, response.body

    draft = Product.create!(
      category: @category,
      name: "Hidden Kada",
      selling_price: 400,
      stock_quantity: 1,
      status: :draft
    )
    get sitemap_path
    assert_no_match piece_url(draft.slug), response.body

    get "/robots.txt"
    assert_response :success
    assert_match "Sitemap: https://denshe.shop/sitemap.xml", response.body
    assert_match "Disallow: /admin", response.body
  end

  test "home introduces the cabinet" do
    get root_url

    assert_response :success
    assert_select "h1", /chosen to feel like you/i
    assert_select "img[alt='DeNshe Jewellery']"
    assert_select "a", text: /Aurelia Hoops/
  end

  test "shop, collection, and piece pages render" do
    get shop_path
    assert_response :success
    assert_select "h1", "Every piece"
    assert_select "article.piece", 1

    get shop_path, params: { material: "Anti-tarnish", sort: "price-asc" }
    assert_response :success
    assert_select "article.piece", 1

    get shop_path, params: { material: "Missing metal" }
    assert_response :success
    assert_select "h2", "Nothing matches."

    get collection_path(@category.slug)
    assert_response :success
    assert_select "h1", "Earrings"

    get piece_path(@product.slug)
    assert_response :success
    assert_select "h1", "Aurelia Hoops"
    assert_select ".stock-note", /only one/i
  end

  test "story, care, contact, mystery box, and jewellery box render" do
    get story_path
    assert_response :success
    assert_select "h1", /two friends/i
    assert_select "h2", text: "Okay, but who are we?"
    assert_select "p.story__moment", text: /Let's actually do it/
    assert_select "h2", text: "Worn your way."

    get care_path
    assert_response :success
    assert_select "h1", /care guide/i

    get contact_path
    assert_response :success
    assert_select "h1", /write to us/i

    get mystery_box_path
    assert_response :success
    assert_select "h1", /box/i
    assert_select "[data-controller='fitting']"
    assert_select "[data-fitting-value-param='rose_gold']", text: /Rose gold/
    assert_select "[data-metal='rose']"

    get jewellery_box_path
    assert_response :success
    assert_select "h1", /jewellery box/i
  end

  test "a selected piece can be checked out through to payment" do
    get shop_path
    assert_select "button", text: /Select/

    post cart_items_path, params: { slug: @product.slug }
    assert_redirected_to shop_path

    follow_redirect!
    assert_select "a", text: /Selected/

    get cart_path
    assert_response :success
    assert_select "h1", /selected pieces/i
    assert_select "a", text: "Aurelia Hoops"

    get checkout_path
    assert_response :success
    assert_select "h1", /where should we send it/i

    post checkout_path, params: { checkout: { name: "", phone: "9876543210", line1: "14 Sea Face", city: "Mumbai", state: "Maharashtra", pin_code: "400001", billing_same: "1" } }
    assert_response :unprocessable_entity

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
    assert_redirected_to checkout_payment_path

    follow_redirect!
    assert_response :success
    assert_select "h1", "Payment."
    assert_match(/nothing has been charged/i, response.body)
    assert_match(/Aisha Shah/, response.body)
    assert_match(/14 Sea Face/, response.body)

    order = Order.order(:id).last
    assert_equal "unpaid", order.payment_status
    assert_equal "Aurelia Hoops", order.order_items.sole.name
    assert_equal 1, @product.reload.stock_quantity
    assert_equal 0, Cart.new(session).count
  end

  test "checkout and payment ask for a selection first" do
    get checkout_path
    assert_redirected_to cart_path

    get checkout_payment_path
    assert_redirected_to cart_path
  end

  test "a held storefront shows launching soon until the preview link" do
    previous = Rails.application.config.x.storefront_held
    Rails.application.config.x.storefront_held = true

    get root_url
    assert_response :success
    assert_select "h1", "Launching Soon!"
    assert_select "img[alt='DeNshe Jewellery']"

    get shop_path
    assert_select "h1", "Launching Soon!"
    assert_select "article.piece", 0

    get storefront_preview_path("wrong-token")
    assert_response :not_found

    get storefront_preview_path(Rails.application.config.x.storefront_preview_token)
    assert_redirected_to root_path
    follow_redirect!
    assert_select "h1", /chosen to feel like you/i

    get close_storefront_preview_path
    assert_redirected_to root_path
    follow_redirect!
    assert_select "h1", "Launching Soon!"
  ensure
    Rails.application.config.x.storefront_held = previous
  end

  test "sold pieces stay reachable and say so" do
    @product.update!(stock_quantity: 0)

    get piece_path(@product.slug)
    assert_response :success
    assert_select ".stock-note", /found its person/i

    get shop_path
    assert_select "article.piece", 0
  end
end
