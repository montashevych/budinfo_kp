module Admin
  class CategoriesController < Admin::ApplicationController
    def find_resource(param)
      find_resource_by_slug_or_id(Category, param)
    end
  end
end
