# frozen_string_literal: true

class SitemapsController < ApplicationController
  allow_unauthenticated_access

  def show
    @categories = Category.select(:slug, :updated_at)
    @products = Product.active.select(:slug, :updated_at)
    render formats: :xml
  end
end
