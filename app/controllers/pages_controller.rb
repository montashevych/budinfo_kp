class PagesController < ApplicationController
  allow_unauthenticated_access

  def delivery
    set_meta_tags title: t("meta.titles.delivery"), description: t("meta.descriptions.delivery")
  end
end
