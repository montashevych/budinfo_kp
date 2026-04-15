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

  test "line item unit_price stays fixed when product price changes later" do
    product = products(:bolt)
    snapshot = product.price
    order = Order.create!(email: "snap@example.com", total: 0)
    order.order_items.create!(product: product, quantity: 1, unit_price: snapshot)
    order.recalculate_total!
    product.update!(price: snapshot + 50)
    order.reload
    li = order.order_items.find_by(product: product)
    assert_equal snapshot, li.unit_price
    assert_equal snapshot, order.total
  end
end
