require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  test "index" do
    get products_path
    assert_response :success
    assert_select "turbo-frame#products"
    assert_match products(:bolt).title_uk, @response.body
  end

  test "index hides inactive products" do
    get products_path
    assert_no_match products(:hidden).title_uk, @response.body
  end

  test "index turbo frame returns partial without layout" do
    get products_path, headers: { "Turbo-Frame" => "products" }
    assert_response :success
    assert_select "turbo-frame#products"
    assert_no_match(/<body/i, @response.body)
  end

  test "index paginates" do
    get products_path
    assert_match products(:bolt).title_uk, @response.body
    assert_no_match products(:cement).title_uk, @response.body

    get products_path, params: { page: 2 }
    assert_response :success
    assert_match products(:cement).title_uk, @response.body
  end

  test "index filters by category_id" do
    get products_path, params: { category_id: categories(:root).id }
    assert_response :success
  end

  test "index ignores invalid category_id" do
    get products_path, params: { category_id: "999999" }
    assert_response :success
  end

  test "index filters by price range" do
    get products_path, params: { min_price: 200, max_price: 300 }
    assert_response :success
  end

  test "show by slug" do
    cement = products(:cement)
    get product_path(cement)
    assert_response :success
    assert_select "form.button_to[action=?]", add_cart_path
    assert_select "input[name=product_id][value=?]", cement.id.to_s
  end

  test "inactive product returns not found" do
    get product_path(products(:hidden))
    assert_response :not_found
  end

  test "unknown slug returns not found" do
    get product_path("no-such-product")
    assert_response :not_found
  end
end
