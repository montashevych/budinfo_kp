# frozen_string_literal: true

require "administrate/base_dashboard"

class OrderDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    public_token: Field::String,
    user: Field::BelongsTo,
    status: Field::Select.with_options(
      searchable: false,
      collection: ->(_field) { Order.statuses.keys }
    ),
    total: Field::Number.with_options(decimals: 2, searchable: false),
    email: Field::String,
    shipping_name: Field::String,
    shipping_phone: Field::String,
    shipping_address: Field::Text,
    order_items: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    status
    total
    email
    user
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    public_token
    status
    total
    email
    user
    shipping_name
    shipping_phone
    shipping_address
    order_items
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    user
    status
    email
    shipping_name
    shipping_phone
    shipping_address
  ].freeze

  COLLECTION_FILTERS = {}.freeze
end
