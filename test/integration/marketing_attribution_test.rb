require "test_helper"

class MarketingAttributionTest < ActionDispatch::IntegrationTest
  setup do
    @category = Category.create!(name: "Earrings", slug: "earrings", position: 1)
    @product = Product.create!(
      category: @category,
      name: "Karamsad Daily Hoops",
      selling_price: 699,
      stock_quantity: 5,
      status: :active,
      collection_line: :western
    )
    @admin_user = AdminUser.create!(
      name: "Neshma",
      email: "neshma_test@denshe.shop",
      password: "password123",
      password_confirmation: "password123",
      role: :super_admin
    )
  end

  test "tracks instagram UTM visit and attributes completed order" do
    insta_headers = {
      "HTTP_USER_AGENT" => "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Instagram 300.0.0.0"
    }

    # 1. Visitor clicks Instagram link with UTMs
    get shop_path(
      utm_source: "instagram",
      utm_medium: "reels",
      utm_campaign: "karamsad_earrings_reel_01"
    ), headers: insta_headers
    assert_response :success

    visit = Ahoy::Visit.last
    assert_not_nil visit
    assert_equal "instagram", visit.utm_source
    assert_equal "reels", visit.utm_medium
    assert_equal "karamsad_earrings_reel_01", visit.utm_campaign

    # 2. Visitor views a piece
    get piece_path(@product.slug), headers: insta_headers
    assert_response :success
    assert_equal 1, Ahoy::Event.where(name: "Viewed piece").count

    # 3. Visitor adds piece to cart
    post cart_items_path, params: { slug: @product.slug }, headers: insta_headers
    assert_equal 1, Ahoy::Event.where(name: "Added to cart").count

    # 4. Visitor checks out
    post checkout_path, params: {
      checkout: {
        name: "Pooja Patel",
        phone: "9876543210",
        email: "pooja@example.com",
        line1: "Station Road",
        city: "Karamsad",
        state: "Gujarat",
        pin_code: "388325"
      }
    }, headers: insta_headers

    order = Order.last
    assert_not_nil order
    assert_equal "Pooja Patel", order.guest_name
    assert_equal visit.id, order.ahoy_visit_id
    assert_equal "karamsad_earrings_reel_01", order.ahoy_visit.utm_campaign

    # 5. Admin can view attribution dashboard
    post admin_user_session_path, params: {
      admin_user: { email: @admin_user.email, password: "password123" }
    }
    follow_redirect!
    assert_response :success

    get admin_marketing_attribution_path
    assert_response :success
    assert_match "karamsad_earrings_reel_01", response.body
    assert_match "Instagram &amp; Campaign Attribution", response.body
  end
end
