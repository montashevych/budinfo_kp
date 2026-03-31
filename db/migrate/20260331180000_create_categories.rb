class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name_uk, null: false
      t.string :name_ru
      t.string :slug, null: false
      t.references :parent, foreign_key: { to_table: :categories }

      t.timestamps
    end

    add_index :categories, :slug, unique: true
  end
end
