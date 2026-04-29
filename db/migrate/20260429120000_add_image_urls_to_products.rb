# frozen_string_literal: true

class AddImageUrlsToProducts < ActiveRecord::Migration[8.1]
  def change
    return if column_exists?(:products, :image_urls)

    add_column :products, :image_urls, :string, array: true, default: [], null: false
  end
end
