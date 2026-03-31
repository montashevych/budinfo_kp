require "administrate/base_dashboard"

class UserDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    email_address: Field::String,
    password: Field::Password,
    password_confirmation: Field::Password,
    role: Field::Select.with_options(
      searchable: false,
      collection: ->(_field) { User.roles.keys }
    ),
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    email_address
    role
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    email_address
    role
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    email_address
    role
    password
    password_confirmation
  ].freeze

  COLLECTION_FILTERS = {}.freeze
end
