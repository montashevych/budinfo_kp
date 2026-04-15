class CategoriesController < ApplicationController
  allow_unauthenticated_access

  def index
    set_meta_tags title: t("meta.titles.categories_index")
    @categories = Category.roots.ordered.includes(:children)
  end

  def show
    @category = Category.find_by!(slug: params[:slug])
    @products = @category.products.active.with_attached_images.order(:title_uk)
    set_meta_tags(
      title: @category.display_name,
      description: t("meta.descriptions.category", name: @category.display_name)
    )
  end
end
