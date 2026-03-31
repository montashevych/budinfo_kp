class Product < ApplicationRecord
  ALLOWED_IMAGE_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
  MAX_IMAGE_SIZE = 5.megabytes

  belongs_to :category
  has_many_attached :images

  validates :title_uk, presence: true
  validates :slug, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :stock, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :sku, uniqueness: { allow_blank: true }
  validate :acceptable_images

  before_validation :assign_slug, :normalize_sku

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

  private

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

  def acceptable_images
    images.each do |image|
      next unless image.blob.present?

      unless ALLOWED_IMAGE_TYPES.include?(image.content_type)
        errors.add(:images, :invalid_type)
        break
      end
      if image.byte_size > MAX_IMAGE_SIZE
        errors.add(:images, :too_large)
        break
      end
    end
  end
end
