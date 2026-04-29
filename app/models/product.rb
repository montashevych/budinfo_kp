# frozen_string_literal: true

class Product < ApplicationRecord
  ALLOWED_IMAGE_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
  MAX_IMAGE_URLS = 20
  MAX_UPLOADED_IMAGES = 20
  # Stored blobs after optional resize/JPEG re-encode (see ProductUploadImageProcessor).
  MAX_STORED_IMAGE_BYTES = 512.kilobytes
  # Raw upload limit before processing (admin controller).
  MAX_RAW_UPLOAD_BYTES = 25.megabytes

  belongs_to :category
  has_many :order_items, dependent: :restrict_with_error
  has_many_attached :images

  validates :title_uk, presence: true
  validates :slug, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :sku, uniqueness: { allow_blank: true }
  validate :acceptable_image_urls
  validate :acceptable_uploaded_images
  validate :uploaded_images_count

  before_validation :assign_slug, :normalize_sku, :compact_image_urls

  scope :active, -> { where(active: true) }
  scope :in_stock, -> { where("stock > 0") }
  scope :by_category, ->(slug) {
    return none if slug.blank?

    joins(:category).where(categories: { slug: slug.to_s })
  }

  def self.filter_by_price_range(scope, min_price: nil, max_price: nil)
    rel = scope
    rel = rel.where("products.price >= ?", min_price) if min_price
    rel = rel.where("products.price <= ?", max_price) if max_price
    rel
  end

  def display_title
    case I18n.locale
    when :ru then title_ru.presence || title_uk
    else title_uk
    end
  end

  def display_description
    case I18n.locale
    when :ru then description_ru.presence || description_uk
    else description_uk
    end
  end

  def to_param
    slug
  end

  # Administrate: one HTTPS/HTTP URL per line (optional; complements uploads).
  def image_urls_for_form
    Array(image_urls).join("\n")
  end

  def image_urls_for_form=(text)
    self.image_urls = self.class.normalize_image_url_lines(text)
  end

  def media_summary
    u = images.attachments.size
    l = Array(image_urls).size
    return "—" if u.zero? && l.zero?

    I18n.t("products.admin_media_summary", files: u, links: l)
  end

  def first_external_image_url
    Array(image_urls).find { |x| self.class.permitted_image_url?(x) }
  end

  def display_images?
    images.attached? || first_external_image_url.present?
  end

  def self.normalize_image_url_lines(text)
    text.to_s.split(/[\r\n]+/).map(&:strip).reject(&:blank?).uniq
  end

  def self.permitted_image_url?(raw)
    uri = URI.parse(raw.to_s.strip)
    return false unless uri.is_a?(URI::HTTP)
    return false if uri.host.blank?

    %w[http https].include?(uri.scheme.to_s.downcase)
  rescue URI::InvalidURIError
    false
  end

  private

  def compact_image_urls
    self.image_urls = Array(image_urls).map(&:to_s).map(&:strip).reject(&:blank?).uniq
  end

  def normalize_sku
    self.sku = sku.presence
  end

  def assign_slug
    return if slug.present?

    base = title_uk.to_s.parameterize(locale: :uk)
    base = "product" if base.blank?
    candidate = base
    suffix = 0
    while Product.where.not(id: id).exists?(slug: candidate)
      suffix += 1
      candidate = "#{base}-#{suffix}"
    end
    self.slug = candidate
  end

  def acceptable_image_urls
    urls = Array(image_urls)
    if urls.size > MAX_IMAGE_URLS
      errors.add(:image_urls, :too_many, max: MAX_IMAGE_URLS)
      return
    end

    urls.each do |url|
      unless self.class.permitted_image_url?(url)
        errors.add(:image_urls, :invalid_url)
        break
      end
    end
  end

  def uploaded_images_count
    return unless images.attachments.size > MAX_UPLOADED_IMAGES

    errors.add(:images, :too_many_attached, max: MAX_UPLOADED_IMAGES)
  end

  def acceptable_uploaded_images
    images.each do |image|
      next unless image.blob.present?

      unless ALLOWED_IMAGE_TYPES.include?(image.content_type)
        errors.add(:images, :invalid_type)
        break
      end
      if image.byte_size > MAX_STORED_IMAGE_BYTES
        errors.add(:images, :too_large)
        break
      end
    end
  end
end
