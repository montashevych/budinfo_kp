class CategoriesController < ApplicationController
  allow_unauthenticated_access

  def index
    @categories = Category.roots.ordered.includes(:children)
  end

  def show
    @category = Category.find_by!(slug: params[:slug])
    @products = @category.products.order(:id)
  end
end
