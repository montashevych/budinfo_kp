# frozen_string_literal: true

# Demo product photos are downloaded from Wikimedia Commons (open licenses). Keep attributions
# on a public “Credits” or imprint page in production if you ship these files.
#
# | File (Commons)              | License      | Author / note                    |
# |-----------------------------|--------------|----------------------------------|
# | Bolsa de cemento Plasticor  | CC BY 4.0    | Just a Man                       |
# | Ceemnt CEM II … na paletach | CC BY-SA 4.0 | Krugerr (cement bags on pallets)|
# | Glass wool insulation       | CC BY-SA 3.0 | Radomil (glass/mineral wool)    |
# | Measuring-tape              | Public domain| Evan-Amos                        |

require "open-uri"

def attach_open_license_demo_images(product, sources:)
  return if product.images.attached?

  sources.each do |src|
    url = src.fetch(:url)
    filename = src.fetch(:filename)
    io = URI(url).open(
      "User-Agent" => "BudinfoSeeds/1.0 (+https://wikimedia.org)",
      read_timeout: 30,
      open_timeout: 15
    )
    product.images.attach(
      io:,
      filename:,
      content_type: "image/jpeg"
    )
  end
rescue OpenURI::HTTPError, SocketError, Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED => e
  warn "Demo images skipped for #{product.slug}: #{e.message}"
end

password = ENV.fetch("ADMIN_SEED_PASSWORD", "changeme_in_production")
User.find_or_initialize_by(email_address: "admin@example.com").tap do |user|
  user.password = password
  user.password_confirmation = password
  user.role = :admin
  user.save!
end

# Demo categories only — in production the admin adds the real tree via Administrate (Phase C).
dry_mixes = Category.find_or_create_by!(slug: "sukhi-sumishi") do |c|
  c.name_uk = "Сухі суміші"
  c.name_ru = "Сухие смеси"
end

Category.find_or_create_by!(slug: "tsement") do |c|
  c.name_uk = "Цемент"
  c.name_ru = "Цемент"
  c.parent = dry_mixes
end

Category.find_or_create_by!(slug: "uteplennya") do |c|
  c.name_uk = "Утеплення"
  c.name_ru = "Утепление"
end

Category.find_or_create_by!(slug: "pilomaterialy") do |c|
  c.name_uk = "Пиломатеріали"
  c.name_ru = "Пиломатериалы"
end

Category.find_or_create_by!(slug: "instrument") do |c|
  c.name_uk = "Інструмент"
  c.name_ru = "Инструмент"
end

cement_cat = Category.find_by!(slug: "tsement")
cement_product = Product.find_or_create_by!(slug: "cement-portland-25kg") do |p|
  p.category = cement_cat
  p.title_uk = "Цемент портландцемент, 25 кг"
  p.title_ru = "Цемент портландцемент, 25 кг"
  p.description_uk = "Мішок 25 кг. Для будівельних розчинів та бетону."
  p.description_ru = "Мешок 25 кг. Для строительных растворов и бетона."
  p.price = 189.00
  p.stock = 40
  p.active = true
  p.sku = "DEMO-CEM-25"
end

insulation = Category.find_by!(slug: "uteplennya")
minvata_product = Product.find_or_create_by!(slug: "minvata-100mm") do |p|
  p.category = insulation
  p.title_uk = "Мінеральна вата 100 мм (плита)"
  p.title_ru = "Минеральная вата 100 мм (плита)"
  p.price = 420.50
  p.stock = 15
  p.active = true
  p.sku = "DEMO-MIN-100"
end

tools = Category.find_by!(slug: "instrument")
ruletka_product = Product.find_or_create_by!(slug: "ruletka-5m") do |p|
  p.category = tools
  p.title_uk = "Рулетка 5 м"
  p.title_ru = "Рулетка 5 м"
  p.price = 120.00
  p.stock = 0
  p.active = true
end

# Wikimedia Commons direct JPEGs (skipped if offline). Only when product has no images yet.
attach_open_license_demo_images(cement_product, sources: [
  {
    url: "https://upload.wikimedia.org/wikipedia/commons/b/bd/Bolsa_de_cemento_Plasticor_40_kg.jpg",
    filename: "demo-cement-bag-plasticor-wikimedia.jpg"
  },
  {
    url: "https://upload.wikimedia.org/wikipedia/commons/a/a7/Ceemnt_CEM_II_A-V_42%2C5_R_MOCNY_na_paletach.jpg",
    filename: "demo-cement-bags-pallet-wikimedia.jpg"
  }
])

attach_open_license_demo_images(minvata_product, sources: [
  {
    url: "https://upload.wikimedia.org/wikipedia/commons/a/a1/Glass_wool_insulation.jpg",
    filename: "demo-glass-wool-insulation-wikimedia.jpg"
  }
])

attach_open_license_demo_images(ruletka_product, sources: [
  {
    url: "https://upload.wikimedia.org/wikipedia/commons/1/17/Measuring-tape.jpg",
    filename: "demo-measuring-tape-wikimedia.jpg"
  }
])
