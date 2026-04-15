# frozen_string_literal: true

# Served via config.exceptions_app → /404 and /500. Inherits from ActionController::Base so a DB
# outage does not break the error page (no session / cart queries).
class ErrorsController < ActionController::Base
  layout "error"

  before_action :set_error_locale

  def not_found
    render :not_found, status: :not_found, formats: :html
  end

  def internal_server_error
    render :internal_server_error, status: :internal_server_error, formats: :html
  end

  private

  def set_error_locale
    header = request.env["HTTP_ACCEPT_LANGUAGE"].to_s
    I18n.locale = if header.match?(/\bru\b/i)
                    :ru
                  elsif header.match?(/\b(uk|ua)\b/i)
                    :uk
                  else
                    I18n.default_locale
                  end
  end
end
