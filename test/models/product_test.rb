# frozen_string_literal: true

require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "by_category scope matches category slug" do
    assert_includes Product.by_category("root-fixture"), products(:cement)
  end

  test "filter_by_price_range uses bound parameters only" do
    scope = Product.where(id: products(:cement).id)
    result = Product.filter_by_price_range(scope, min_price: 200, max_price: 300)
    assert_equal 1, result.count
  end

  test "display_title prefers locale" do
    I18n.with_locale(:ru) do
      assert_equal "Цемент 50 кг", products(:cement).display_title
    end
  end

  test "rejects invalid slug format when slug set explicitly" do
    p = Product.new(
      title_uk: "Test",
      slug: "Invalid_Slug",
      category: categories(:root),
      price: 1,
      stock: 1,
      active: true
    )
    assert_not p.valid?
    assert p.errors[:slug].any?
  end

  test "rejects negative price" do
    p = Product.new(
      title_uk: "Test",
      category: categories(:root),
      price: -1,
      stock: 1,
      active: true
    )
    assert_not p.valid?
    assert p.errors[:price].any?
  end

  test "rejects negative stock" do
    p = Product.new(
      title_uk: "Test",
      category: categories(:root),
      price: 1,
      stock: -1,
      active: true
    )
    assert_not p.valid?
    assert p.errors[:stock].any?
  end

  test "active scope excludes inactive products" do
    assert_includes Product.active, products(:cement)
    assert_not_includes Product.active, products(:hidden)
  end

  test "rejects invalid image url" do
    p = Product.new(
      title_uk: "Test",
      category: categories(:root),
      price: 1,
      stock: 1,
      active: true,
      image_urls: [ "javascript:alert(1)" ]
    )
    assert_not p.valid?
    assert p.errors[:image_urls].any?
  end

  test "accepts https image url" do
    p = Product.new(
      title_uk: "Test Img",
      category: categories(:root),
      price: 1,
      stock: 1,
      active: true,
      image_urls: [ "https://upload.wikimedia.org/wikipedia/commons/1/17/Measuring-tape.jpg" ]
    )
    assert p.valid?, p.errors.full_messages.inspect
  end

  test "in_stock scope excludes zero stock" do
    out = Product.create!(
      title_uk: "Out",
      category: categories(:root),
      price: 1,
      stock: 0,
      active: true
    )
    assert_not_includes Product.in_stock, out
  end
end
