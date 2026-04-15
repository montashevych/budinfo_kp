# frozen_string_literal: true

module Admin
  class OrderItemsController < Admin::ApplicationController
    def scoped_resource
      resource_class.includes(:order, :product).order(created_at: :desc)
    end
  end
end
