class CategoriesController < ApplicationController
  allow_unauthenticated_access

  def index
    @categories = Category.roots.ordered.includes(:children)
  end

  def show
    @category = Category.find_by!(slug: params[:slug])
    @products = @category.products.active.with_attached_images.order(:title_uk)
  end
end
