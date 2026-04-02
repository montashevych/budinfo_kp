# frozen_string_literal: true

require "test_helper"

class CartTest < ActiveSupport::TestCase
  setup { Rails.cache.clear }

  test "add merges quantities and respects stock" do
    cart = Cart.new("cart/t/test")
    bolt = products(:bolt)

    assert_equal :ok, cart.add(bolt.id, 2)
    assert_equal :ok, cart.add(bolt.id, 1)
    assert_equal 3, cart.raw[bolt.id.to_s]

    assert_equal :out_of_stock, cart.add(bolt.id, bolt.stock)
  end

  test "add rejects inactive product" do
    cart = Cart.new("cart/t/test2")
    assert_equal :inactive, cart.add(products(:hidden).id, 1)
  end

  test "total uses line items" do
    cart = Cart.new("cart/t/test3")
    cart.add(products(:bolt).id, 2)
    assert_equal BigDecimal("7.0"), cart.total
  end

  test "merge_guest_into_user combines quantities and drops guest key" do
    guest_key = Cart.cache_key_guest("tok")
    user_key = Cart.cache_key_user(users(:one).id)
    Rails.cache.write(guest_key, { products(:bolt).id.to_s => 2 }, expires_in: Cart::CACHE_TTL)
    Rails.cache.write(user_key, { products(:cement).id.to_s => 1 }, expires_in: Cart::CACHE_TTL)

    Cart.merge_guest_into_user!(guest_token: "tok", user: users(:one))

    assert_nil Rails.cache.read(guest_key)
    merged = Rails.cache.read(user_key)
    assert_equal 2, merged[products(:bolt).id.to_s]
    assert_equal 1, merged[products(:cement).id.to_s]
  end
end
