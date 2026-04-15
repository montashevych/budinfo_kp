class ApplicationMailer < ActionMailer::Base
  layout "mailer"

  before_action :set_default_mailer_locale

  # Merge **kwargs — `mail(to:, subject:)` can arrive as keywords, not the first Hash, so a plain
  # `headers = {}` misses them and From never applied (see DEVELOPMENT_PLAN D.3 deferred notes).
  def mail(headers = {}, **kwargs, &block)
    h = headers.to_h.merge(kwargs).deep_dup.symbolize_keys
    from_env = ENV["MAILER_FROM"].to_s.delete_prefix("\uFEFF").strip.presence
    h[:from] = h[:from].presence || from_env || "noreply@example.com"
    super(h, &block)
  end

  private

  def set_default_mailer_locale
    I18n.locale = I18n.default_locale
  end

  def mailer_from_address
    ENV["MAILER_FROM"].to_s.delete_prefix("\uFEFF").strip.presence || "noreply@example.com"
  end
end
