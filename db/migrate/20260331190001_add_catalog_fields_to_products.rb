class AddCatalogFieldsToProducts < ActiveRecord::Migration[8.1]
  def change
    change_table :products, bulk: true do |t|
      t.string :title_uk, null: false
      t.string :title_ru
      t.text :description_uk
      t.text :description_ru
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0
      t.integer :stock, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.string :sku
      t.string :slug, null: false
    end

    add_index :products, :slug, unique: true
    add_index :products, :sku, unique: true
  end
end
