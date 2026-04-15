class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    set_meta_tags title: t("meta.titles.home")
    @home_promotions = HomePromotion.active.ordered.with_attached_image.to_a
  end
end
