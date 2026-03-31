class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"
  layout "mailer"

  before_action :set_default_mailer_locale

  private

  def set_default_mailer_locale
    I18n.locale = I18n.default_locale
  end
end
