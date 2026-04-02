# frozen_string_literal: true

# Preview at /rails/mailers (development) — seed or create an order first if empty.
class OrderMailerPreview < ActionMailer::Preview
  def confirmation
    order = Order.includes(order_items: :product).order(created_at: :desc).first
    raise "No orders in DB — run checkout or seeds" unless order

    OrderMailer.confirmation(order)
  end

  def notify_admin
    order = Order.includes(order_items: :product).order(created_at: :desc).first
    raise "No orders in DB — run checkout or seeds" unless order

    OrderMailer.notify_admin(order, to: ENV.fetch("SHOP_NOTIFICATION_EMAIL", "shop@example.com"))
  end
end
