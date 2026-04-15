# frozen_string_literal: true

require "test_helper"

class OrderMailerTest < ActionMailer::TestCase
  setup do
    @order = Order.create!(
      email: "customer@example.com",
      shipping_name: "Test Customer",
      shipping_phone: "+380501112233",
      shipping_address: "Kyiv",
      total: 0
    )
    @order.order_items.create!(product: products(:bolt), quantity: 2, unit_price: products(:bolt).price)
    @order.recalculate_total!
    @order.reload
  end

  test "confirmation" do
    email = OrderMailer.confirmation(@order)
    assert_equal [@order.email], email.to
    assert_includes email.subject, @order.id.to_s
    assert_includes email.html_part.body.to_s, products(:bolt).title_uk
  end

  test "notify_admin" do
    email = OrderMailer.notify_admin(@order, to: "shop@example.com")
    assert_equal ["shop@example.com"], email.to
    assert_includes email.subject, @order.id.to_s
    assert_includes email.html_part.body.to_s, @order.email
  end
end
