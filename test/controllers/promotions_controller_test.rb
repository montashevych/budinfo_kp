# frozen_string_literal: true

require "test_helper"

class PromotionsControllerTest < ActionDispatch::IntegrationTest
  def tiny_png_io
    StringIO.new(Base64.decode64(
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
    ))
  end

  test "show active promotion by slug" do
    p = HomePromotion.new(
      title: "Spring sale",
      slug: "spring-sale",
      active: true,
      position: 0,
      teaser: "Limited time offers.",
      body: "Details line one.\n\nLine two."
    )
    p.image.attach(io: tiny_png_io, filename: "x.png", content_type: "image/png")
    p.save!

    get promotion_path("spring-sale")
    assert_response :success
    assert_select "h1", text: "Spring sale"
    assert_match "Limited time offers.", @response.body
    assert_match "Details line one.", @response.body
    assert_select "title", text: /Spring sale/
  end

  test "inactive promotion returns not found" do
    p = HomePromotion.create!(
      title: "Old",
      slug: "old-promo",
      active: false,
      position: 0
    )

    get promotion_path("old-promo")
    assert_response :not_found
  end

  test "unknown slug returns not found" do
    get promotion_path("missing-slug")
    assert_response :not_found
  end
end
