# frozen_string_literal: true

# DiskService raises if ActiveStorage::Current.url_options is blank when building signed /disk URLs
# after a variant redirect. Prefer proxy URLs in development (see development.rb); this fallback
# fixes leftover redirect links and edge cases where Current is empty.
module ActiveStorage::DiskUrlOptionsFallback
  def url_options
    ActiveStorage::Current.url_options.presence ||
      Rails.application.config.active_storage.default_url_options.presence ||
      {}
  end
end

if Rails.env.development?
  apply_disk_url_fallback = lambda do
    next unless defined?(ActiveStorage::Service::DiskService)

    disk = ActiveStorage::Service::DiskService
    next if disk.ancestors.include?(ActiveStorage::DiskUrlOptionsFallback)

    disk.prepend(ActiveStorage::DiskUrlOptionsFallback)
  end

  Rails.application.config.after_initialize { apply_disk_url_fallback.call }
  Rails.application.config.to_prepare { apply_disk_url_fallback.call }
end
