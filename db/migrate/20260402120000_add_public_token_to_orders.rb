# frozen_string_literal: true

class AddPublicTokenToOrders < ActiveRecord::Migration[8.1]
  class Order < ApplicationRecord
    self.table_name = "orders"
  end

  def up
    add_column :orders, :public_token, :string
    Order.reset_column_information
    Order.find_each do |o|
      o.update_column(:public_token, SecureRandom.urlsafe_base64(32))
    end
    change_column_null :orders, :public_token, false
    add_index :orders, :public_token, unique: true
  end

  def down
    remove_index :orders, :public_token
    remove_column :orders, :public_token
  end
end
