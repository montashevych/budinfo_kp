require "administrate/base_dashboard"
require "administrate/field/active_storage"

class ProductDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    active: Field::Boolean,
    order_items: Field::HasMany,
    category: Field::BelongsTo,
    description_ru: Field::Text,
    description_uk: Field::Text,
    images: Field::ActiveStorage.with_options(
      index_display_preview: true,
      index_preview_size: [ 72, 72 ],
      show_preview_size: [ 480, 480 ]
    ),
    price: Field::Number.with_options(decimals: 2, searchable: false),
    sku: Field::String,
    slug: Field::String,
    stock: Field::Number,
    title_ru: Field::String,
    title_uk: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    title_uk
    category
    price
    active
    images
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    title_uk
    title_ru
    slug
    sku
    category
    price
    stock
    active
    description_uk
    description_ru
    images
    order_items
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    title_uk
    title_ru
    slug
    sku
    category
    price
    stock
    active
    description_uk
    description_ru
    images
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def permitted_attributes(action = nil)
    super + [ images: [] ]
  end
end
