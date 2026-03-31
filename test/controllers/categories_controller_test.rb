require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  test "index" do
    get categories_path
    assert_response :success
  end

  test "show by slug" do
    get category_path(categories(:root))
    assert_response :success
  end

  test "unknown slug returns not found" do
    get category_path("does-not-exist")
    assert_response :not_found
  end
end
