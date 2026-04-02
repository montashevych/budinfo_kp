# frozen_string_literal: true

module Admin
  class HomePromotionsController < Admin::ApplicationController
    def find_resource(param)
      find_resource_by_slug_or_id(HomePromotion, param)
    end

    def scoped_resource
      resource_class.with_attached_image
    end
  end
end
