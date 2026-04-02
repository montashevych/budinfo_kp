# frozen_string_literal: true

require "test_helper"

class CheckoutTest < ActiveSupport::TestCase
  setup { Rails.cache.clear }

  test "creates order with line items snapshots price and decrements stock" do
    key = Cart.cache_key_user(users(:one).id)
    cart = Cart.new(key)
    bolt = products(:bolt)
    cement = products(:cement)
    assert_equal :ok, cart.add(bolt.id, 2)
    assert_equal :ok, cart.add(cement.id, 1)

    stock_before_bolt = bolt.stock
    stock_before_cement = cement.stock

    result = Checkout.call(
      cart: cart,
      user: users(:one),
      params: {
        email: "buyer@example.com",
        shipping_name: "Test Buyer",
        shipping_phone: "+380501112233",
        shipping_address: "Kyiv, test st 1"
      }
    )

    assert result.success?
    order = result.order
    assert order.public_token.present?
    assert_equal 2, order.order_items.count
    assert_equal users(:one), order.user

    bolt.reload
    cement.reload
    assert_equal stock_before_bolt - 2, bolt.stock
    assert_equal stock_before_cement - 1, cement.stock

    li_bolt = order.order_items.find_by(product: bolt)
    assert_equal 2, li_bolt.quantity
    assert_equal bolt.price, li_bolt.unit_price

    assert cart.empty?
    assert_equal (2 * bolt.price + 1 * cement.price), order.total
  end

  test "guest checkout without user" do
    key = "cart/g/test-guest-checkout"
    Rails.cache.write(key, { products(:bolt).id.to_s => 1 }, expires_in: Cart::CACHE_TTL)
    cart = Cart.new(key)
    bolt = products(:bolt)
    expected_stock = bolt.stock - 1

    result = Checkout.call(
      cart: cart,
      user: nil,
      params: {
        email: "guest@example.com",
        shipping_name: "Guest",
        shipping_phone: "+380501112233",
        shipping_address: "Lviv"
      }
    )

    assert result.success?
    assert_nil result.order.user
    assert_equal expected_stock, bolt.reload.stock
  end

  test "empty cart" do
    key = Cart.cache_key_user(users(:two).id)
    cart = Cart.new(key)
    result = Checkout.call(cart: cart, user: nil, params: { email: "a@b.com", shipping_name: "x", shipping_phone: "1", shipping_address: "y" })
    assert_equal :empty_cart, result.failure
  end

  test "invalid checkout params" do
    key = Cart.cache_key_user(users(:two).id)
    cart = Cart.new(key)
    cart.add(products(:bolt).id, 1)
    result = Checkout.call(cart: cart, user: nil, params: { email: "", shipping_name: "", shipping_phone: "", shipping_address: "" })
    assert_equal :invalid, result.failure
    assert result.order.errors.any?
  end
end
