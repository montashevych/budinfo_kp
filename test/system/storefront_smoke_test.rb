# frozen_string_literal: true

require "application_system_test_case"

class StorefrontSmokeTest < ApplicationSystemTestCase
  include ActionMailer::TestHelper

  setup { Rails.cache.clear }

  test "home and catalog load" do
    visit root_path
    assert_selector "body"

    visit products_path
    assert_selector "body"
  end

  test "product page add to cart and checkout" do
    visit product_path(products(:bolt))
    click_button I18n.t("products.cart.add_to_cart")
    visit new_checkout_path
    fill_in "order_email", with: "sys-smoke@example.com"
    fill_in "order_shipping_name", with: "Smoke Test"
    fill_in "order_shipping_phone", with: "+380501112233"
    fill_in "order_shipping_address", with: "Test address"

    assert_emails 1 do
      click_button I18n.t("checkouts.submit")
      perform_enqueued_jobs
    end

    assert_text I18n.t("order_confirmations.heading")
    assert_text "sys-smoke@example.com"
  end
end
