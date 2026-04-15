require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

require "pagy"

module App
  class Application < Rails::Application
    config.load_defaults 8.1

    config.autoload_lib(ignore: %w[assets tasks])

    config.i18n.default_locale = :uk
    config.i18n.available_locales = %i[uk ru]
    config.i18n.fallbacks = { ru: %i[uk] }

    # Localized HTML error pages via ErrorsController (see config/routes.rb /404, /500).
    config.exceptions_app = routes
  end
end
