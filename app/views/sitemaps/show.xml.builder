# frozen_string_literal: true

xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.urlset "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9" do
  xml.url do
    xml.loc root_url
    xml.changefreq "daily"
    xml.priority "1.0"
  end

  xml.url do
    xml.loc categories_url
    xml.changefreq "weekly"
    xml.priority "0.9"
  end

  xml.url do
    xml.loc products_url
    xml.changefreq "daily"
    xml.priority "0.9"
  end

  xml.url do
    xml.loc delivery_url
    xml.changefreq "monthly"
    xml.priority "0.5"
  end

  xml.url do
    xml.loc new_contact_url
    xml.changefreq "monthly"
    xml.priority "0.5"
  end

  @categories.find_each do |cat|
    xml.url do
      xml.loc category_url(slug: cat.slug)
      xml.lastmod cat.updated_at&.iso8601
      xml.changefreq "weekly"
      xml.priority "0.8"
    end
  end

  @products.find_each do |product|
    xml.url do
      xml.loc product_url(slug: product.slug)
      xml.lastmod product.updated_at&.iso8601
      xml.changefreq "weekly"
      xml.priority "0.7"
    end
  end
end
