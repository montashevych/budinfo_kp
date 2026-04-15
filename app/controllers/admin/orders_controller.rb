# frozen_string_literal: true

module Admin
  class OrdersController < Admin::ApplicationController
    def scoped_resource
      resource_class.order(created_at: :desc)
    end
  end
end
