# frozen_string_literal: true

class Order < ApplicationRecord
  belongs_to :user, optional: true
  has_many :order_items, dependent: :destroy

  enum :status, {
    pending: "pending",
    confirmed: "confirmed",
    shipped: "shipped",
    cancelled: "cancelled"
  }, default: :pending, validate: true

  before_validation :ensure_public_token, on: :create

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :total, numericality: { greater_than_or_equal_to: 0 }
  validates :shipping_name, :shipping_phone, :shipping_address, presence: true, on: :checkout

  # Recalculate total from line items (call from checkout / after item changes).
  def recalculate_total!
    sum = order_items.reduce(0.to_d) { |acc, li| acc + (li.quantity * li.unit_price) }
    update_column(:total, sum)
  end

  private

  def ensure_public_token
    return if public_token.present?

    self.public_token = SecureRandom.urlsafe_base64(32)
  end
end
