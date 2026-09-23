require "test_helper"

class AdminFlowTest < ActionDispatch::IntegrationTest
  setup do
    @admin = AdminUser.create!(
      name: "Neshma",
      email: "neshma-flow@denshe.in",
      password: "denshe-admin-123",
      password_confirmation: "denshe-admin-123",
      role: :super_admin
    )
    @category = Category.create!(name: "Earrings", position: 1)
  end

  test "admin can sign in and create a product with purchase price and stock" do
    post admin_user_session_path, params: {
      admin_user: { email: @admin.email, password: "denshe-admin-123" }
    }
    follow_redirect!
    assert_response :success

    get new_admin_product_path
    assert_response :success

    assert_difference -> { Product.count }, 1 do
      post admin_products_path, params: {
        product: {
          category_id: @category.id,
          name: "Aurelia Hoops",
          sku: "DN-EAR-001",
          purchase_price: 180,
          selling_price: 699,
          stock_quantity: 12,
          low_stock_threshold: 2,
          status: "active",
          short_description: "Everyday hoops."
        }
      }
    end

    product = Product.find_by!(sku: "DN-EAR-001")
    follow_redirect!
    assert_response :success
    assert_equal 12, product.stock_quantity
    assert_equal 180, product.purchase_price
    assert product.inventory_movements.purchase.exists?
  end

  test "admin can search products by name, sku, or slug including earrings" do
    post admin_user_session_path, params: {
      admin_user: { email: @admin.email, password: "denshe-admin-123" }
    }
    follow_redirect!

    hoops = Product.create!(
      category: @category,
      name: "Aurelia Hoops",
      sku: "DN-EAR-001",
      selling_price: 699,
      stock_quantity: 4
    )
    Product.create!(
      category: @category,
      name: "Pearl Drop Earrings",
      sku: "DN-EAR-002",
      selling_price: 599,
      stock_quantity: 2
    )
    rings = Category.create!(name: "Rings", position: 2)
    Product.create!(
      category: rings,
      name: "Quiet Ring",
      sku: "DN-RNG-010",
      selling_price: 499,
      stock_quantity: 1
    )

    get admin_dashboard_path
    assert_response :success
    assert_select "form.admin-search-bar input[name=search]"
    assert_select "a[href=?]", admin_products_path(scope: "earrings")

    get admin_products_path, params: { search: "DN-EAR-001" }
    assert_response :success
    assert_includes response.body, hoops.name
    assert_includes response.body, "Search name, SKU, or slug"
    assert_not_includes response.body, "Quiet Ring"

    get admin_products_path, params: { search: "quiet-ring" }
    assert_response :success
    assert_includes response.body, "Quiet Ring"
    assert_not_includes response.body, "Aurelia Hoops"

    get admin_products_path, params: { scope: "earrings", search: "Pearl" }
    assert_response :success
    assert_includes response.body, "Pearl Drop Earrings"
    assert_not_includes response.body, "Quiet Ring"

    get admin_category_path(@category), params: { search: "aurelia" }
    assert_response :success
    assert_includes response.body, "Aurelia Hoops"
    assert_includes response.body, "Search earrings"
    assert_not_includes response.body, "Quiet Ring"
  end

  test "admin can open category reports and filter earrings" do
    post admin_user_session_path, params: {
      admin_user: { email: @admin.email, password: "denshe-admin-123" }
    }
    follow_redirect!

    get admin_reports_path
    assert_response :success

    get admin_reports_path, params: { category_id: @category.id }
    assert_response :success
    assert_select "h3, h2, caption, .panel", text: /Earrings|Totals/i
  end
end
