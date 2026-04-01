module Admin
  class UsersController < Admin::ApplicationController
    def resource_params
      permitted = params.require(resource_class.model_name.param_key).permit(
        :email_address, :role, :password, :password_confirmation
      )
      if permitted[:password].blank?
        permitted.delete(:password)
        permitted.delete(:password_confirmation)
      end
      permitted
    end
  end
end
