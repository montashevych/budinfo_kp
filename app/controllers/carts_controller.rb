# frozen_string_literal: true

class CartsController < ApplicationController
  allow_unauthenticated_access

  def show
    @line_items = current_cart.line_items
    set_meta_tags title: t("meta.titles.cart"), robots: "noindex, nofollow"
  end

  def add
    result = current_cart.add(params[:product_id], add_quantity)
    redirect_after_cart_change(result)
  end

  def update_line
    result = current_cart.set_quantity(params[:product_id], params[:quantity])
    redirect_after_cart_change(result, success_message: t("carts.updated"))
  end

  def remove_line
    current_cart.remove(params[:product_id])
    redirect_to cart_path, notice: t("carts.removed"), status: :see_other
  end

  private

  def add_quantity
    q = params[:quantity].to_i
    q.positive? ? q : 1
  end

  def redirect_after_cart_change(result, success_message: t("carts.added"))
    case result
    when :ok
      redirect_back_or_cart notice: success_message
    when :out_of_stock
      redirect_back_or_cart alert: t("carts.out_of_stock")
    when :inactive, :invalid_product, :invalid
      redirect_back_or_cart alert: t("carts.unavailable")
    else
      redirect_back_or_cart alert: t("carts.unavailable")
    end
  end

  def redirect_back_or_cart(flash_hash)
    redirect_back fallback_location: cart_path, **flash_hash, status: :see_other
  end
end
