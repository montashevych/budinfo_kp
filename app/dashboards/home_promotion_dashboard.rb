# frozen_string_literal: true

require "administrate/base_dashboard"
require "administrate/field/active_storage"

class HomePromotionDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    title: Field::String,
    teaser: Field::Text,
    slug: Field::String,
    body: Field::Text,
    position: Field::Number,
    active: Field::Boolean,
    image: Field::ActiveStorage.with_options(
      index_display_preview: true,
      index_preview_size: [ 72, 72 ],
      show_preview_size: [ 640, 360 ]
    ),
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    position
    title
    active
    image
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    title
    teaser
    slug
    body
    position
    active
    image
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    title
    teaser
    slug
    body
    position
    active
    image
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(home_promotion)
    home_promotion.title
  end
end
