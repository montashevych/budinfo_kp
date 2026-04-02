# frozen_string_literal: true

require "test_helper"

class HomePromotionTest < ActiveSupport::TestCase
  def tiny_png_io
    # 1×1 transparent PNG
    StringIO.new(Base64.decode64(
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
    ))
  end

  test "inactive record may omit image" do
    p = HomePromotion.new(title: "Sale", slug: "sale", active: false, position: 0)
    assert p.valid?
    assert p.save
  end

  test "active record requires image" do
    p = HomePromotion.new(title: "Sale", slug: "sale-two", active: true, position: 0)
    assert_not p.valid?
    assert p.errors[:image].any?
  end

  test "active record with png image is valid" do
    p = HomePromotion.new(title: "Sale", slug: "sale-three", active: true, position: 0, body: "Details")
    p.image.attach(io: tiny_png_io, filename: "x.png", content_type: "image/png")
    assert p.valid?, p.errors.full_messages.inspect
    assert p.save
  end

  test "slug auto from title when blank" do
    p = HomePromotion.new(title: "Великий розпродаж", active: false, position: 1)
    p.valid?
    assert p.slug.present?
  end

  test "active scope returns only active records" do
    HomePromotion.delete_all
    on = HomePromotion.new(title: "On", slug: "scope-on", active: true, position: 0)
    on.image.attach(io: tiny_png_io, filename: "on.png", content_type: "image/png")
    on.save!
    HomePromotion.create!(title: "Off", slug: "scope-off", active: false, position: 1)

    ids = HomePromotion.active.pluck(:id)
    assert_includes ids, on.id
    assert_equal 1, ids.size
  end

  test "slug must match allowed format" do
    p = HomePromotion.new(title: "X", slug: "Invalid_Slug", active: false, position: 0)
    assert_not p.valid?
    assert p.errors[:slug].any?
  end

  test "active ordered scope" do
    HomePromotion.destroy_all
    a = HomePromotion.new(title: "B", slug: "b", active: true, position: 2)
    a.image.attach(io: tiny_png_io, filename: "b.png", content_type: "image/png")
    a.save!
    b = HomePromotion.new(title: "A", slug: "a", active: true, position: 1)
    b.image.attach(io: tiny_png_io, filename: "a.png", content_type: "image/png")
    b.save!
    c = HomePromotion.create!(title: "Off", slug: "off", active: false, position: 0)
    ids = HomePromotion.active.ordered.pluck(:id)
    assert_equal [ b.id, a.id ], ids
    assert_not_includes ids, c.id
  end
end
