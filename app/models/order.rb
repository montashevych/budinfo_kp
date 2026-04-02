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

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :total, numericality: { greater_than_or_equal_to: 0 }

  # Recalculate total from line items (call from checkout / after item changes).
  def recalculate_total!
    sum = order_items.reduce(0.to_d) { |acc, li| acc + (li.quantity * li.unit_price) }
    update_column(:total, sum)
  end
end
