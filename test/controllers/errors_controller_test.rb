# frozen_string_literal: true

require "test_helper"

class ErrorsControllerTest < ActionDispatch::IntegrationTest
  # No catalog fixtures; keeps this file usable even when the test DB has FK noise elsewhere.
  fixtures []
  test "not_found" do
    get "/404"
    assert_response :not_found
    assert_match I18n.t("errors.pages.not_found.title", locale: :uk), @response.body
  end

  test "internal_server_error" do
    get "/500"
    assert_response :internal_server_error
    assert_match I18n.t("errors.pages.internal_server_error.title", locale: :uk), @response.body
  end

  test "not_found respects Accept-Language ru" do
    get "/404", headers: { "Accept-Language" => "ru" }
    assert_response :not_found
    assert_match I18n.t("errors.pages.not_found.title", locale: :ru), @response.body
  end
end
