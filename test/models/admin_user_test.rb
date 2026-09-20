require "test_helper"

class AdminUserTest < ActiveSupport::TestCase
  test "creates separate named admin accounts" do
    user = AdminUser.create!(
      name: "Neshma",
      email: "neshma-test@denshe.in",
      password: "a-strong-password",
      password_confirmation: "a-strong-password",
      role: :super_admin
    )

    assert user.super_admin?
    assert_equal "Neshma", user.display_name
  end
end
