# frozen_string_literal: true

# Creates an Order from the current cart: row-locks products, snapshots unit_price, decrements stock, clears cart.
class Checkout
  Result = Struct.new(:order, :failure, keyword_init: true) do
    def success?
      failure.nil? && order&.persisted?
    end
  end

  def self.call(cart:, user:, params:)
    new(cart: cart, user: user, params: params).call
  end

  def initialize(cart:, user:, params:)
    @cart = cart
    @user = user
    @params = params
  end

  def call
    lines = @cart.line_items
    return Result.new(failure: :empty_cart) if lines.empty?

    order = nil
    success = false
    Order.transaction do
      product_ids = lines.map { |li| li.product.id }.uniq.sort
      locked_rows = Product.active.where(id: product_ids).order(:id).lock.to_a
      by_id = locked_rows.index_by(&:id)

      unless lines.all? { |li| by_id[li.product.id] }
        raise ActiveRecord::Rollback
      end

      lines.each do |li|
        p = by_id[li.product.id]
        raise ActiveRecord::Rollback if p.stock < li.quantity
      end

      order = Order.new(
        user: @user,
        status: :pending,
        total: 0,
        email: @params[:email].to_s.strip,
        shipping_name: @params[:shipping_name].to_s.strip,
        shipping_phone: @params[:shipping_phone].to_s.strip,
        shipping_address: @params[:shipping_address].to_s.strip
      )
      unless order.valid?(:checkout) && order.save
        raise ActiveRecord::Rollback
      end

      lines.each do |li|
        p = by_id[li.product.id]
        order.order_items.create!(product_id: p.id, quantity: li.quantity, unit_price: p.price)
      end
      order.recalculate_total!

      lines.each do |li|
        p = by_id[li.product.id]
        p.reload
        raise ActiveRecord::Rollback if p.stock < li.quantity

        p.update!(stock: p.stock - li.quantity)
      end

      @cart.clear
      success = true
    end

    if success
      Result.new(order: order.reload)
    elsif order&.errors&.any?
      Result.new(order: order, failure: :invalid)
    else
      Result.new(failure: :stale_cart)
    end
  end
end
