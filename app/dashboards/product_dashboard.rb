require "administrate/base_dashboard"

class ProductDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    active: Field::Boolean,
    category: Field::BelongsTo,
    description_ru: Field::Text,
    description_uk: Field::Text,
    images_attachments: Field::HasMany,
    images_blobs: Field::HasMany,
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
    images_attachments
    created_at
    updated_at
  ].freeze

  # Image uploads: add a custom Active Storage field later (Phase C.2); avoid editing raw attachments here.
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
  ].freeze

  COLLECTION_FILTERS = {}.freeze
end
