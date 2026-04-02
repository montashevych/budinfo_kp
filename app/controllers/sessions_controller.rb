class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: t("auth.sessions.rate_limited") }

  def new
  end

  def create
    guest_cart_token = cookies.signed[Cart::COOKIE]
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      Cart.merge_guest_into_user!(guest_token: guest_cart_token, user: user)
      cookies.delete(Cart::COOKIE)
      redirect_to after_authentication_url, notice: t("auth.sessions.signed_in")
    else
      redirect_to new_session_path, alert: t("auth.sessions.invalid_credentials")
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, notice: t("auth.sessions.signed_out"), status: :see_other
  end
end
