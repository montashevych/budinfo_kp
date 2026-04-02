# frozen_string_literal: true

require "test_helper"

class CartsControllerTest < ActionDispatch::IntegrationTest
  setup { Rails.cache.clear }

  test "show empty cart" do
    get cart_path
    assert_response :success
    assert_match I18n.t("carts.empty", locale: :uk), response.body
  end

  test "guest add then show lists product" do
    bolt = products(:bolt)
    post add_cart_path, params: { product_id: bolt.id }
    assert_redirected_to cart_path
    get cart_path
    assert_response :success
    assert_includes response.body, bolt.title_uk
  end

  test "add as turbo_stream updates badges and product line UI" do
    bolt = products(:bolt)
    post add_cart_path, params: { product_id: bolt.id }, as: :turbo_stream
    assert_response :success
    assert_includes response.content_type, "turbo-stream"
    assert_match "cart-nav-badge-desktop", response.body
    assert_match "cart-nav-badge-mobile-bar", response.body
    assert_match "add-to-cart-product-#{bolt.id}", response.body
    assert_not_includes response.body, 'target="cart-toast"'
  end

  test "update_line as turbo_stream refreshes badges and line" do
    bolt = products(:bolt)
    post add_cart_path, params: { product_id: bolt.id }
    patch update_line_cart_path, params: { product_id: bolt.id, quantity: 2 }, as: :turbo_stream
    assert_response :success
    assert_includes response.content_type, "turbo-stream"
    assert_match "cart-nav-badge-desktop", response.body
    assert_match "add-to-cart-product-#{bolt.id}", response.body
  end

  test "add inactive product as turbo_stream appends error toast" do
    post add_cart_path, params: { product_id: products(:hidden).id }, as: :turbo_stream
    assert_response :success
    assert_includes response.content_type, "turbo-stream"
    assert_match I18n.t("carts.unavailable", locale: :uk), response.body
  end

  test "add inactive product flashes alert" do
    post add_cart_path, params: { product_id: products(:hidden).id }
    assert_redirected_to cart_path
    assert_equal I18n.t("carts.unavailable", locale: :uk), flash[:alert]
  end

  test "update line quantity" do
    bolt = products(:bolt)
    post add_cart_path, params: { product_id: bolt.id }
    patch update_line_cart_path, params: { product_id: bolt.id, quantity: 3 }
    assert_redirected_to cart_path
    assert_equal I18n.t("carts.updated", locale: :uk), flash[:notice]
    get cart_path
    assert_includes response.body, "3"
  end

  test "remove line" do
    bolt = products(:bolt)
    post add_cart_path, params: { product_id: bolt.id }
    delete remove_line_cart_path(product_id: bolt.id)
    assert_redirected_to cart_path
    assert_equal I18n.t("carts.removed", locale: :uk), flash[:notice]
  end

  test "sign in merges guest cart into user cart" do
    bolt = products(:bolt)
    post add_cart_path, params: { product_id: bolt.id }

    post session_path, params: { email_address: users(:one).email_address, password: "password" }
    assert_redirected_to root_path

    get cart_path
    assert_response :success
    assert_includes response.body, bolt.title_uk
  end
end
