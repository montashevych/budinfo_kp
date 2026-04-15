class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    @user.role = :customer
    if @user.save
      guest_cart_token = cookies.signed[Cart::COOKIE]
      start_new_session_for @user
      Cart.merge_guest_into_user!(guest_token: guest_cart_token, user: @user)
      cookies.delete(Cart::COOKIE)
      redirect_to after_authentication_url, notice: t("auth.registration.success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
