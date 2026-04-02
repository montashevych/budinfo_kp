class HomeController < ApplicationController
  allow_unauthenticated_access

  def index
    set_meta_tags title: t("meta.titles.home")
  end
end
