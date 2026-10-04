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

  test "admin can restock a product from the product page" do
    post admin_user_session_path, params: {
      admin_user: { email: @admin.email, password: "denshe-admin-123" }
    }
    follow_redirect!

    product = Product.create!(
      category: @category,
      name: "Aurelia Hoops",
      sku: "DN-EAR-RESTOCK",
      selling_price: 699,
      purchase_price: 180,
      stock_quantity: 0,
      quantity_purchased: 1,
      status: :active
    )

    get admin_product_path(product)
    assert_response :success
    assert_select "a[href=?]", restock_admin_product_path(product)

    get restock_admin_product_path(product)
    assert_response :success
    assert_match "Current stock", response.body
    assert_select "input[name='restock[quantity]']"

    assert_difference -> { product.reload.stock_quantity }, 3 do
      assert_difference -> { product.reload.quantity_purchased }, 3 do
        post apply_restock_admin_product_path(product), params: {
          restock: { quantity: 3, reason: "Mahavir lot" }
        }
      end
    end

    follow_redirect!
    assert_response :success
    assert_match "Stock is now 3", response.body
    assert product.inventory_movements.purchase.where(reason: "Mahavir lot", quantity: 3).exists?
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

  test "admin can remove a product design and set the storefront primary image" do
    post admin_user_session_path, params: {
      admin_user: { email: @admin.email, password: "denshe-admin-123" }
    }
    follow_redirect!

    product = Product.create!(
      category: @category,
      name: "Aurelia Hoops",
      sku: "DN-EAR-IMG",
      selling_price: 699,
      stock_quantity: 3
    )
    front = attach_product_image(product, "front.png")
    side = attach_product_image(product, "side.png")
    product.ensure_primary_image!

    get admin_product_path(product)
    assert_response :success
    assert_match "Make primary", response.body
    assert_select "button[data-fullscreen-src]", minimum: 2
    assert_select "button.lightbox__cancel", text: "Cancel"
    assert_match "Remove", response.body

    get edit_admin_product_path(product)
    assert_response :success
    assert_select "input[name='product[primary_image_id]']", count: 2
    assert_select "input[name='product[remove_image_ids][]']", count: 2

    patch set_primary_image_admin_product_path(product, image_id: side.id)
    follow_redirect!
    assert_response :success
    assert_equal side.id, product.reload.primary_image.id

    delete remove_image_admin_product_path(product, image_id: side.id)
    follow_redirect!
    assert_response :success
    assert_equal 1, product.reload.images.count
    assert_equal front.id, product.primary_image.id
  end

  test "a second product with the same SKU explains the problem instead of erroring" do
    Product.create!(category: @category, name: "Heart Cuff Kada", selling_price: 1200, sku: "MV-KDA-001")
    post admin_user_session_path, params: {
      admin_user: { email: @admin.email, password: "denshe-admin-123" }
    }

    assert_no_difference -> { Product.count } do
      post admin_products_path, params: {
        product: {
          category_id: @category.id,
          name: "Heart Cuff Kada",
          sku: "MV-KDA-001",
          selling_price: 1200,
          status: "draft"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_match(/already/i, response.body)
  end

  test "admin order pages list the products on the order" do
    post admin_user_session_path, params: {
      admin_user: { email: @admin.email, password: "denshe-admin-123" }
    }
    product = Product.create!(
      category: @category,
      name: "Silver Heart Stud Earrings",
      sku: "DN-EAR-100",
      selling_price: 180,
      stock_quantity: 1,
      status: :active
    )
    order = Order.create!(guest_name: "neshma", guest_email: "neshma@example.com", subtotal: 180, total: 180)
    order.order_items.create!(
      product: product,
      name: product.name,
      sku: product.sku,
      quantity: 1,
      unit_price: 180,
      item_type: :catalogue
    )

    get admin_orders_path
    assert_response :success
    assert_match "Silver Heart Stud Earrings", response.body

    get admin_order_path(order)
    assert_response :success
    assert_match "Silver Heart Stud Earrings", response.body
    assert_match admin_product_path(product), response.body
  end

  test "product list photos are served from this site" do
    product = Product.create!(category: @category, name: "Leaf Kada", selling_price: 1400, stock_quantity: 1)
    product.images.attach(io: StringIO.new("image-bytes"), filename: "leaf.jpg", content_type: "image/jpeg")
    product.ensure_primary_image!
    post admin_user_session_path, params: {
      admin_user: { email: @admin.email, password: "denshe-admin-123" }
    }

    get admin_products_path
    assert_response :success
    assert_match %r{/rails/active_storage/blobs/proxy/}, response.body
  end

  test "admin can upload a short clip and remove it" do
    post admin_user_session_path, params: {
      admin_user: { email: @admin.email, password: "denshe-admin-123" }
    }
    product = Product.create!(category: @category, name: "Aurelia Hoops", selling_price: 699, stock_quantity: 1, status: :active)
    clip = Tempfile.new([ "turn", ".mp4" ])
    clip.binmode
    clip.write("clip-bytes")
    clip.rewind
    upload = Rack::Test::UploadedFile.new(clip.path, "video/mp4", true, original_filename: "turn.mp4")

    patch admin_product_path(product), params: { product: { clips: [ upload ] } }
    follow_redirect!
    assert_response :success
    assert product.reload.clips.attached?
    assert_match "turn.mp4", response.body

    get edit_admin_product_path(product)
    assert_select "input[type=file][name='product[clips][]']"
    assert_select "input[name='product[remove_clip_ids][]']"

    notes = Tempfile.new([ "notes", ".txt" ])
    notes.write("nope")
    notes.rewind
    bad = Rack::Test::UploadedFile.new(notes.path, "text/plain", false, original_filename: "notes.txt")
    patch admin_product_path(product), params: { product: { clips: [ bad ] } }
    follow_redirect!
    assert_match "MP4, MOV, or WebM", flash[:alert]
    assert_equal 1, product.reload.clips.count

    delete remove_clip_admin_product_path(product, clip_id: product.clips.first.id)
    follow_redirect!
    assert_not product.reload.clips.attached?
  ensure
    clip&.close!
    notes&.close!
  end
end
