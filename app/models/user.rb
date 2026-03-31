class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  enum :role, { customer: 0, admin: 1 }, default: :customer

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_digest&.last(10)
  end
end
