# frozen_string_literal: true

module CurrentCart
  extend ActiveSupport::Concern

  included do
    helper_method :current_cart, :cart_item_count, :cart_quantity_for
  end

  def cart_item_count
    current_cart.item_count
  end

  def cart_quantity_for(product)
    current_cart.raw[product.id.to_s].to_i
  end

  private

  def current_cart
    @current_cart ||= Cart.new(cart_cache_key)
  end

  def cart_cache_key
    if current_user
      Cart.cache_key_user(current_user.id)
    else
      Cart.cache_key_guest(ensure_guest_cart_token!)
    end
  end

  def ensure_guest_cart_token!
    existing = cookies.signed[Cart::COOKIE]
    return existing if existing.present?

    token = SecureRandom.urlsafe_base64(24)
    cookies.signed.permanent[Cart::COOKIE] = {
      value: token,
      httponly: true,
      same_site: :lax
    }
    token
  end
end
