# frozen_string_literal: true

require "test_helper"

class OrderTest < ActiveSupport::TestCase
  test "recalculate_total sums line items" do
    order = Order.create!(email: "buyer@example.com", total: 0)
    product = products(:cement)
    order.order_items.create!(product: product, quantity: 2, unit_price: product.price)
    order.order_items.create!(product: product, quantity: 1, unit_price: 10)
    order.recalculate_total!
    order.reload
    assert_equal (2 * product.price + 10), order.total
  end

  test "requires valid email" do
    order = Order.new(email: "", total: 0)
    assert_not order.valid?
  end
end
