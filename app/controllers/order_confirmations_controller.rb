# frozen_string_literal: true

class OrderConfirmationsController < ApplicationController
  allow_unauthenticated_access

  def show
    @order = Order.includes(order_items: :product).find_by!(public_token: params[:public_token])
    set_meta_tags title: t("meta.titles.order_confirmation", id: @order.id), robots: "noindex, nofollow"
  end
end
