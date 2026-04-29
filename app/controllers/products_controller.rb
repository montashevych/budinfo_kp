class ProductsController < ApplicationController
  allow_unauthenticated_access

  def index
    set_meta_tags title: t("meta.titles.products_index")
    scope = Product.active.with_attached_images.includes(:category).order(:title_uk)
    scope = apply_filters(scope)
    @filter_categories = Category.roots.ordered.includes(:children)
    @pagy, @products = pagy(
      :offset,
      scope,
      limit: pagination_limit,
      overflow: :last_page
    )

    if request.headers["Turbo-Frame"] == "products"
      render partial: "products/index_frame", layout: false
    else
      render :index
    end
  end

  def show
    @product = Product.active.with_attached_images.includes(:category).find_by!(slug: params[:slug])
    desc = helpers.strip_tags(@product.display_description.to_s).squish
    desc = desc.presence || t("layouts.application.meta_description")
    set_meta_tags title: @product.display_title, description: desc
    og_image = if @product.images.attached?
      rails_blob_url(@product.images.first)
    else
      @product.first_external_image_url
    end
    if og_image.present?
      set_meta_tags og: {
        title: @product.display_title,
        description: desc,
        image: og_image,
        type: "website"
      }
    end
  end

  private

  def pagination_limit
    Rails.env.test? ? 1 : 12
  end

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
