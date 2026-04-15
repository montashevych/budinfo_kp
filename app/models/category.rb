class Category < ApplicationRecord
  belongs_to :parent, class_name: "Category", optional: true
  has_many :children, class_name: "Category", foreign_key: :parent_id, inverse_of: :parent, dependent: :nullify
  has_many :products, dependent: :restrict_with_exception

  validates :name_uk, presence: true
  validates :slug, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  validate :parent_is_not_self

  before_validation :assign_slug

  scope :roots, -> { where(parent_id: nil) }
  scope :ordered, -> { order(:name_uk) }

  def display_name
    case I18n.locale
    when :ru then name_ru.presence || name_uk
    else name_uk
    end
  end

  def to_param
    slug
  end

  private

  def assign_slug
    return if slug.present?

    base = name_uk.to_s.parameterize(locale: :uk)
    base = "category" if base.blank?
    candidate = base
    suffix = 0
    while Category.where.not(id: id).exists?(slug: candidate)
      suffix += 1
      candidate = "#{base}-#{suffix}"
    end
    self.slug = candidate
  end

  def parent_is_not_self
    errors.add(:parent_id, :invalid) if parent_id.present? && parent_id == id
  end
end
