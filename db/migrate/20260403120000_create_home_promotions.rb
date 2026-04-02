# frozen_string_literal: true

class CreateHomePromotions < ActiveRecord::Migration[8.1]
  def change
    create_table :home_promotions do |t|
      t.string :title, null: false
      t.text :teaser
      t.string :slug, null: false
      t.text :body
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :home_promotions, :slug, unique: true
    add_index :home_promotions, :active
    add_index :home_promotions, :position
  end
end
