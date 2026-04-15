# frozen_string_literal: true

class RobotsController < ApplicationController
  allow_unauthenticated_access

  def show
    body = <<~TXT
      User-agent: *
      Disallow: /admin
      Disallow: /rails/

      Sitemap: #{sitemap_url}
    TXT
    render plain: body, content_type: "text/plain"
  end
end
