module Admin
  class ProductsController < Admin::ApplicationController
    def find_resource(param)
      find_resource_by_slug_or_id(Product, param)
    end
  end
end
