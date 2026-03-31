require "test_helper"

class AdminAccessTest < ActionDispatch::IntegrationTest
  test "guest is redirected to sign in" do
    get admin_root_url
    assert_redirected_to new_session_url
  end

  test "customer is redirected to storefront with alert" do
    sign_in_as(users(:one))
    get admin_root_url
    assert_redirected_to root_url
    assert_equal I18n.t("admin.forbidden"), flash[:alert]
  end

  test "admin can open admin root" do
    sign_in_as(users(:admin))
    get admin_root_url
    assert_response :success
  end

  test "admin category show resolves slug from to_param" do
    sign_in_as(users(:admin))
    get admin_category_url(categories(:root))
    assert_response :success
  end
end
