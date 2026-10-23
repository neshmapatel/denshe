require "test_helper"

class AdminCuratedGiftsTest < ActionDispatch::IntegrationTest
  setup do
    @admin = AdminUser.create!(
      name: "Neshma",
      email: "neshma-gifts@denshe.in",
      password: "denshe-admin-123",
      password_confirmation: "denshe-admin-123",
      role: :super_admin
    )
    CuratedGift.seed_defaults!
  end

  test "admin can view curated gifts list and defaults" do
    sign_in_admin
    get admin_curated_gifts_path
    assert_response :success
    assert_match "Treasure Drop — Little Finds", response.body
    assert_match "Treasure Drop — The Signature Edit", response.body
    assert_match "499", response.body
    assert_match "1999", response.body
  end

  test "admin can create a new curated gift with pricing, discount and picture" do
    sign_in_admin
    get new_admin_curated_gift_path
    assert_response :success

    image_file = fixture_file_upload(Rails.root.join("app/assets/images/curated_gifts/little-finds.jpg"), "image/jpeg")

    assert_difference -> { CuratedGift.count }, 1 do
      post admin_curated_gifts_path, params: {
        curated_gift: {
          name: "Treasure Drop — Festive Glow",
          product_title: "Festive Glow | Festive Mystery Jar | ₹1,499",
          subtitle: "Festive surprise",
          price: 1499,
          compare_at_price: 1999,
          discount_percent: 25,
          description: "Curated with vibrant gold and kundan statement studs for the holiday season.",
          status: "active",
          position: 6,
          images: [ image_file ]
        }
      }
    end

    follow_redirect!
    assert_response :success
    gift = CuratedGift.find_by!(slug: "treasure-drop-festive-glow")
    assert_equal 1499.0, gift.price.to_f
    assert_equal 1999.0, gift.compare_at_price.to_f
    assert gift.images.attached?
  end

  test "admin can edit price, discount and description" do
    sign_in_admin
    gift = CuratedGift.find_by!(slug: "little-finds")

    get edit_admin_curated_gift_path(gift)
    assert_response :success

    patch admin_curated_gift_path(gift), params: {
      curated_gift: {
        price: 549,
        compare_at_price: 699,
        description: "Updated description for testing."
      }
    }
    follow_redirect!
    assert_response :success
    gift.reload
    assert_equal 549.0, gift.price.to_f
    assert_equal 699.0, gift.compare_at_price.to_f
    assert_equal "Updated description for testing.", gift.description
  end

  test "admin can delete an image and delete a curated gift" do
    sign_in_admin
    gift = CuratedGift.find_by!(slug: "little-finds")
    assert gift.images.attached?
    image = gift.images.first

    delete delete_image_admin_curated_gift_path(gift, image_id: image.id)
    assert_redirected_to edit_admin_curated_gift_path(gift)
    assert_not gift.reload.images.attached?

    assert_difference -> { CuratedGift.count }, -1 do
      delete admin_curated_gift_path(gift)
    end
    assert_redirected_to admin_curated_gifts_path
  end

  private

  def sign_in_admin
    post admin_user_session_path, params: {
      admin_user: { email: @admin.email, password: "denshe-admin-123" }
    }
    follow_redirect!
  end
end
