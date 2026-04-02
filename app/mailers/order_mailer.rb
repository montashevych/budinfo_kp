# frozen_string_literal: true

class OrderMailer < ApplicationMailer
  def confirmation(order)
    @order = Order.includes(order_items: :product).find(order.id)
    @confirmation_url = order_confirmation_url(@order.public_token)
    mail(
      from: mailer_from_address,
      to: @order.email,
      subject: I18n.t("order_mailer.confirmation.subject", order_id: @order.id)
    )
  end

  def notify_admin(order, to:)
    @order = Order.includes(order_items: :product).find(order.id)
    @confirmation_url = order_confirmation_url(@order.public_token)
    mail(
      from: mailer_from_address,
      to: to,
      subject: I18n.t("order_mailer.notify_admin.subject", order_id: @order.id)
    )
  end
end
