# frozen_string_literal: true

# Promotional slides for the home page carousel (see docs/HOME_PROMOTIONS_PLAN.md).
class HomePromotion < ApplicationRecord
  ALLOWED_IMAGE_TYPES = %w[image/jpeg image/png image/webp image/gif].freeze
  MAX_IMAGE_SIZE = 5.megabytes

  has_one_attached :image

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  validate :acceptable_image
  validate :image_required_when_active

  before_validation :assign_slug_from_title

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc, id: :asc) }

  def to_param
    slug
  end

  private

  def assign_slug_from_title
    return if slug.present?

    base = title.to_s.parameterize(locale: I18n.default_locale)
    base = "promo" if base.blank?
    candidate = base
    suffix = 0
    while HomePromotion.where.not(id: id).exists?(slug: candidate)
      suffix += 1
      candidate = "#{base}-#{suffix}"
    end
    self.slug = candidate
  end

  def image_required_when_active
    return unless active?
    return if image.attached?

    errors.add(:image, :blank)
  end

  def acceptable_image
    return unless image.attached?
    return unless image.blob.present?

    unless ALLOWED_IMAGE_TYPES.include?(image.content_type)
      errors.add(:image, :invalid_type)
      return
    end
    return unless image.byte_size > MAX_IMAGE_SIZE

    errors.add(:image, :too_large)
  end
end
