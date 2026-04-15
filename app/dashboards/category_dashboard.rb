require "administrate/base_dashboard"

class CategoryDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    children: Field::HasMany,
    name_ru: Field::String,
    name_uk: Field::String,
    parent: Field::BelongsTo,
    products: Field::HasMany,
    slug: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    name_uk
    slug
    parent
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name_uk
    name_ru
    slug
    parent
    children
    products
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name_uk
    name_ru
    parent
    slug
  ].freeze

  COLLECTION_FILTERS = {}.freeze
end
