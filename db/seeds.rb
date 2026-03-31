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
