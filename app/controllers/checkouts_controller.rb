# frozen_string_literal: true

class CheckoutsController < ApplicationController
  allow_unauthenticated_access

  def new
    if current_cart.empty?
      redirect_to cart_path, alert: t("checkouts.empty_cart")
      return
    end

    @line_items = current_cart.line_items
    @order = Order.new(email: current_user&.email_address)
  end

  def create
    if current_cart.empty?
      redirect_to cart_path, alert: t("checkouts.empty_cart")
      return
    end

    result = ::Checkout.call(cart: current_cart, user: current_user, params: checkout_params.to_h.symbolize_keys)

    if result.success?
      redirect_to order_confirmation_path(result.order.public_token), notice: t("checkouts.success")
    elsif result.failure == :invalid
      @line_items = current_cart.line_items
      @order = result.order
      flash.now[:alert] = t("checkouts.fix_errors")
      render :new, status: :unprocessable_entity
    else
      redirect_to cart_path, alert: t("checkouts.stale_cart")
    end
  end

  private

  def checkout_params
    params.require(:order).permit(:email, :shipping_name, :shipping_phone, :shipping_address)
  end
end
