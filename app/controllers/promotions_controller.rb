# frozen_string_literal: true

class PromotionsController < ApplicationController
  allow_unauthenticated_access

  def show
    @promotion = HomePromotion.active.with_attached_image.find_by!(slug: params[:slug])
    desc = promotion_meta_description(@promotion)
    set_meta_tags title: @promotion.title, description: desc
    return unless @promotion.image.attached?

    set_meta_tags og: {
      title: @promotion.title,
      description: desc,
      image: rails_blob_url(@promotion.image),
      type: "website"
    }
  end

  private

  def promotion_meta_description(promotion)
    raw = promotion.teaser.to_s.strip.presence || promotion.body.to_s.squish
    text = raw.presence || t("layouts.application.meta_description")
    helpers.truncate(text, length: 160)
  end
end
