# frozen_string_literal: true

class CreateOrdersAndOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, foreign_key: true, null: true
      t.string :status, null: false, default: "pending"
      t.decimal :total, precision: 12, scale: 2, null: false, default: "0.0"
      t.string :email, null: false
      t.string :shipping_name
      t.string :shipping_phone
      t.text :shipping_address

      t.timestamps
    end

    add_index :orders, :status
    add_index :orders, :created_at

    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.decimal :unit_price, precision: 10, scale: 2, null: false

      t.timestamps
    end

    add_index :order_items, %i[order_id product_id]
  end
end
