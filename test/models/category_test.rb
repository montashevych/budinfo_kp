require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "assigns slug from name_uk when blank" do
    c = Category.new(name_uk: "Test Category", name_ru: "Тест")
    c.valid?
    assert_equal "test-category", c.slug
  end

  test "rejects invalid slug format" do
    c = categories(:root)
    c.slug = "Bad_Slug"
    assert_not c.valid?
  end

  test "display_name falls back to uk when ru blank" do
    c = Category.new(name_uk: "Only UK", name_ru: nil)
    I18n.with_locale(:ru) do
      assert_equal "Only UK", c.display_name
    end
  end
end
