require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "home page loads" do
    get root_url
    assert_response :success
    assert_select "h1", /chosen to feel like you/i
  end

  test "admin sign in page loads" do
    get new_admin_user_session_url
    assert_response :success
  end
end
