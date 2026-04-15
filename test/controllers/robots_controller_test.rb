# frozen_string_literal: true

require "test_helper"

class RobotsControllerTest < ActionDispatch::IntegrationTest
  test "show lists sitemap and disallows admin" do
    get robots_url
    assert_response :success
    assert_includes @response.body, "Disallow: /admin"
    assert_includes @response.body, "Sitemap: #{sitemap_url}"
  end
end
