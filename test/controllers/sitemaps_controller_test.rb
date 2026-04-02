# frozen_string_literal: true

require "test_helper"

class SitemapsControllerTest < ActionDispatch::IntegrationTest
  test "show returns valid urlset with catalog urls" do
    get sitemap_url
    assert_response :success
    assert_includes @response.content_type, "xml"
    assert_includes @response.body, "<urlset "
    assert_includes @response.body, root_url
    assert_includes @response.body, category_url(slug: categories(:root).slug)
    assert_includes @response.body, product_url(slug: products(:bolt).slug)
  end
end
