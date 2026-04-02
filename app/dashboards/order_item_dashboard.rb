# frozen_string_literal: true

require "administrate/base_dashboard"

class OrderItemDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    order: Field::BelongsTo,
    product: Field::BelongsTo,
    quantity: Field::Number,
    unit_price: Field::Number.with_options(decimals: 2, searchable: false),
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    order
    product
    quantity
    unit_price
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    order
    product
    quantity
    unit_price
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    order
    product
    quantity
    unit_price
  ].freeze

  COLLECTION_FILTERS = {}.freeze
end
