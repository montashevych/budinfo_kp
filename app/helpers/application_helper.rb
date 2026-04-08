module ApplicationHelper
  include ::MetaTags::ViewHelper
  # Use representation proxy URLs for disk-backed storage so img src never points at
  # /representations/redirect (Turbo snapshots + DiskService URL generation caused 500s).
  def product_variant_image_path(attachment, resize_to_limit)
    variant = attachment.variant(resize_to_limit: resize_to_limit)
    if ActiveStorage::Blob.service.is_a?(ActiveStorage::Service::DiskService)
      rails_blob_representation_proxy_path(
        variant.blob.signed_id,
        variant.variation.key,
        variant.blob.filename
      )
    else
      url_for(variant)
    end
  end

  def product_price(product)
    number_to_currency(
      product.price,
      unit: "₴",
      format: "%n %u",
      separator: ",",
      delimiter: " "
    )
  end

  def locale_link_class(locale)
    base = "rounded px-2 py-1 text-sm font-medium transition-colors"
    if I18n.locale == locale
      "#{base} bg-ink text-on-brand"
    else
      "#{base} text-ink-muted hover:bg-surface-muted hover:text-ink"
    end
  end
end
