password = ENV.fetch("ADMIN_SEED_PASSWORD", "changeme_in_production")
User.find_or_initialize_by(email_address: "admin@example.com").tap do |user|
  user.password = password
  user.password_confirmation = password
  user.role = :admin
  user.save!
end
