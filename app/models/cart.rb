# frozen_string_literal: true

# Guest cart: Rails.cache + signed cookie `cart_token` (30-day TTL on each write).
# Signed-in cart: Rails.cache key `cart/u/:user_id`. On sign-up / sign-in, guest cart merges into user cart.
class Cart
  CACHE_TTL = 30.days
  COOKIE = :cart_token

  Line = Data.define(:product, :quantity)

  class << self
    def merge_guest_into_user!(guest_token:, user:)
      return if guest_token.blank? || user.blank?

      guest_key = cache_key_guest(guest_token)
      user_key = cache_key_user(user.id)
      guest = Rails.cache.read(guest_key) || {}
      return if guest.blank?

      existing = Rails.cache.read(user_key) || {}
      merged = merge_quantities(existing, guest)
      Rails.cache.write(user_key, merged, expires_in: CACHE_TTL)
      Rails.cache.delete(guest_key)
    end

    def cache_key_guest(token)
      "cart/g/#{token}"
    end

    def cache_key_user(user_id)
      "cart/u/#{user_id}"
    end

    def merge_quantities(a, b)
      ah = stringify_quantities(a)
      bh = stringify_quantities(b)
      ah.merge(bh) { |_pid, x, y| x + y }
    end

    def stringify_quantities(h)
      (h || {}).stringify_keys.transform_values { |v| v.to_i }
    end
  end

  def initialize(storage_key)
    @storage_key = storage_key
  end

  def raw
    self.class.stringify_quantities(Rails.cache.read(@storage_key))
  end

  def line_items
    @line_items ||= build_line_items
  end

  def item_count
    qty_by_active_id.values.sum
  end

  def empty?
    qty_by_active_id.empty?
  end

  def quantity_for(product_id)
    qty_by_active_id[product_id.to_i] || 0
  end

  def total
    line_items.sum { |li| li.quantity * li.product.price }
  end

  def add(product_id, quantity = 1)
    pid = product_id.to_i
    qty_add = quantity.to_i
    return :invalid_product if pid <= 0 || qty_add <= 0

    product = Product.active.find_by(id: pid)
    return :inactive unless product

    data = raw
    current_qty = data[pid.to_s].to_i
    new_qty = current_qty + qty_add
    return :out_of_stock if new_qty > product.stock

    data[pid.to_s] = new_qty
    persist(data)
    :ok
  end

  def set_quantity(product_id, quantity)
    pid = product_id.to_i
    qty = quantity.to_i
    return :invalid if pid <= 0

    product = Product.active.find_by(id: pid)
    return :inactive unless product

    data = raw
    if qty <= 0
      data.delete(pid.to_s)
      persist(data)
      return :ok
    end
    return :out_of_stock if qty > product.stock

    data[pid.to_s] = qty
    persist(data)
    :ok
  end

  def remove(product_id)
    pid = product_id.to_i
    data = raw
    data.delete(pid.to_s)
    persist(data)
  end

  def clear
    reset_derived!
    Rails.cache.delete(@storage_key)
  end

  private

  def qty_by_active_id
    @qty_by_active_id ||= build_qty_by_active_id
  end

  def reset_derived!
    @line_items = nil
    @qty_by_active_id = nil
  end

  def build_qty_by_active_id
    data = raw
    return {} if data.empty?

    ids = data.keys.map(&:to_i)
    active_ids = Product.active.where(id: ids).pluck(:id).to_set
    result = {}
    data.each do |pid, qty|
      id = pid.to_i
      result[id] = qty.to_i if active_ids.include?(id)
    end

    pruned = result.transform_keys(&:to_s)
    normalized = data.stringify_keys
    persist(pruned) if pruned != normalized

    result
  end

  def build_line_items
    qty_map = qty_by_active_id
    return [] if qty_map.empty?

    products = Product.active.with_attached_images.where(id: qty_map.keys).index_by(&:id)
    qty_map.filter_map do |pid, qty|
      p = products[pid]
      next unless p

      Line.new(product: p, quantity: qty)
    end.sort_by { |li| li.product.title_uk }
  end

  def persist(data)
    reset_derived!
    if data.empty?
      Rails.cache.delete(@storage_key)
    else
      Rails.cache.write(@storage_key, data, expires_in: self.class::CACHE_TTL)
    end
  end
end
