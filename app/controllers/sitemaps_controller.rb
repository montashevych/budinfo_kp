# frozen_string_literal: true

class SitemapsController < ApplicationController
  allow_unauthenticated_access

  def show
    @categories = Category.select(:id, :slug, :updated_at)
    @products = Product.active.select(:id, :slug, :updated_at)
    render formats: :xml
  end
end
