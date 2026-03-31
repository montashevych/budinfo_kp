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
end
