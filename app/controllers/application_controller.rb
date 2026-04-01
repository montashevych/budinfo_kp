class ApplicationController < ActionController::Base
  include Pagy::Method
  include Authentication
  include CurrentCart
  allow_browser versions: :modern

  stale_when_importmap_changes

  before_action :set_locale

  private

  def set_locale
    if params[:locale].present?
      loc = params[:locale].to_s.to_sym
      session[:locale] = loc.to_s if I18n.available_locales.include?(loc)
    end
    loc = session[:locale].to_s.presence&.to_sym
    I18n.locale = (loc && I18n.available_locales.include?(loc)) ? loc : I18n.default_locale
  end
end
