# frozen_string_literal: true

require "test_helper"

class HomePagePromotionsTest < ActionDispatch::IntegrationTest
  # No catalog fixtures; avoids FK validation noise on `sessions` in some DB states.
  fixtures []

  def tiny_png_io
    StringIO.new(Base64.decode64(
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
    ))
  end

  test "home omits promotions block when none active" do
    HomePromotion.delete_all
    get root_path
    assert_response :success
    assert_no_match(/data-controller="promotion-carousel"/, @response.body)
  end

  test "home shows active promotions with links to detail pages" do
    HomePromotion.delete_all

    a = HomePromotion.new(title: "First", slug: "home-promo-a", active: true, position: 1, teaser: "Teaser A")
    a.image.attach(io: tiny_png_io, filename: "a.png", content_type: "image/png")
    a.save!

    b = HomePromotion.new(title: "Second", slug: "home-promo-b", active: true, position: 0, teaser: "Teaser B")
    b.image.attach(io: tiny_png_io, filename: "b.png", content_type: "image/png")
    b.save!

    get root_path
    assert_response :success
    assert_match(/data-controller="promotion-carousel"/, @response.body)
    assert_select %(a[href="#{promotion_path("home-promo-b")}"])
    assert_select %(a[href="#{promotion_path("home-promo-a")}"])
    assert_match "Second", @response.body
    assert_match "Teaser B", @response.body
  end
end
