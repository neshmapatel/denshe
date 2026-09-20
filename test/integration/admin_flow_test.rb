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
end
