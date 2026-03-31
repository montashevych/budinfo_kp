class ProductsController < ApplicationController
  allow_unauthenticated_access

  def index
    @products = Product.active.with_attached_images.includes(:category).order(:title_uk)
    @products = apply_filters(@products)
    @filter_categories = Category.roots.ordered.includes(:children)
  end

  def show
    @product = Product.active.with_attached_images.includes(:category).find_by!(slug: params[:slug])
  end

  private

  def apply_filters(scope)
    rel = scope
    cid = filter_category_id
    rel = rel.where(category_id: cid) if cid
    min_p, max_p = ordered_price_bounds
    rel = Product.filter_by_price_range(rel, min_price: min_p, max_price: max_p)
    rel
  end

  def filter_category_id
    raw = product_filter_params[:category_id]
    return nil if raw.blank?

    id = Integer(raw)
    Category.exists?(id: id) ? id : nil
  rescue ArgumentError, TypeError
    nil
  end

  def ordered_price_bounds
    min_p = parse_price_bound(product_filter_params[:min_price])
    max_p = parse_price_bound(product_filter_params[:max_price])
    return [ min_p, max_p ] unless min_p && max_p

    min_p <= max_p ? [ min_p, max_p ] : [ max_p, min_p ]
  end

  def parse_price_bound(value)
    return nil if value.blank?

    BigDecimal(value.to_s)
  rescue ArgumentError
    nil
  end

  def product_filter_params
    params.permit(:category_id, :min_price, :max_price)
  end
end
