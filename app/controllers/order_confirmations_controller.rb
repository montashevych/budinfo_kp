# frozen_string_literal: true

class OrderConfirmationsController < ApplicationController
  allow_unauthenticated_access

  def show
    @order = Order.includes(order_items: :product).find_by!(public_token: params[:public_token])
  end
end
