# frozen_string_literal: true

require "test_helper"

class CheckoutsControllerTest < ActionDispatch::IntegrationTest
  setup { Rails.cache.clear }

  test "new redirects when cart empty" do
    get new_checkout_path
    assert_redirected_to cart_path
  end

  test "happy path creates order and shows confirmation" do
    post add_cart_path, params: { product_id: products(:bolt).id }
    get new_checkout_path
    assert_response :success

    assert_difference("Order.count", 1) do
      post checkout_path, params: {
        order: {
          email: "flow@example.com",
          shipping_name: "Flow Test",
          shipping_phone: "+380501112233",
          shipping_address: "Test address line"
        }
      }
    end

    order = Order.order(:created_at).last
    assert_redirected_to order_confirmation_path(order.public_token)
    follow_redirect!
    assert_response :success
    assert_includes response.body, order.email
  end

  test "create re-renders with errors when invalid" do
    post add_cart_path, params: { product_id: products(:cement).id }
    assert_no_difference("Order.count") do
      post checkout_path, params: {
        order: {
          email: "",
          shipping_name: "",
          shipping_phone: "",
          shipping_address: ""
        }
      }
    end
    assert_response :unprocessable_entity
  end
end
