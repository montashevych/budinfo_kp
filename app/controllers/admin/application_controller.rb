# All Administrate controllers inherit from this controller.
module Admin
  class ApplicationController < Administrate::ApplicationController
    include Authentication

    before_action :require_admin

    private

    def require_admin
      return if current_user&.admin?

      redirect_to root_path, alert: t("admin.forbidden")
    end

    # Storefront models use #to_param → slug, so Administrate URLs use slugs; AR still needs a lookup.
    def find_resource_by_slug_or_id(model_class, param)
      s = param.to_s
      if s.match?(/\A\d+\z/)
        model_class.find(s)
      else
        model_class.find_by!(slug: s)
      end
    end
  end
end
