require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

# Pagy does not always load before controllers in all environments (e.g. Docker after Gemfile
# changes). Require explicitly so `include Pagy::Method` in ApplicationController works.
require "pagy"

module App
  class Application < Rails::Application
    config.load_defaults 8.1

    config.autoload_lib(ignore: %w[assets tasks])

    config.i18n.default_locale = :uk
    config.i18n.available_locales = %i[uk ru]
    config.i18n.fallbacks = { ru: %i[uk] }
  end
end
