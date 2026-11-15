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

  test "karamsad local page loads with home studio copy and products" do
    get jewellery_in_karamsad_url
    assert_response :success
    assert_select "h1", /anti-tarnish jewellery, based right here in karamsad/i
    assert_select "title", /Anti-Tarnish Jewellery in Karamsad/i
  end

  test "karamsad redirect alias works" do
    get "/pages/jewellery-in-karamsad"
    assert_redirected_to "/jewellery-in-karamsad"
  end

  test "anand local page loads with structured data and products" do
    get jewellery_in_anand_url
    assert_response :success
    assert_select "h1", /anti-tarnish jewellery, right here in anand/i
    assert_select "title", /Anti-Tarnish Jewellery in Anand/i
  end

  test "anand redirect alias works" do
    get "/pages/jewellery-in-anand"
    assert_redirected_to "/jewellery-in-anand"
  end

  test "vidya nagar local page loads with campus copy" do
    get jewellery_in_vidya_nagar_url
    assert_response :success
    assert_select "h1", /everyday jewellery that keeps up with college life/i
    assert_select "title", /Vallabh Vidyanagar/i
  end

  test "vidya nagar redirect alias works" do
    get "/pages/jewellery-in-vidya-nagar"
    assert_redirected_to "/jewellery-in-vidya-nagar"
  end
end
