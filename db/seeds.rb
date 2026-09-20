# This file is idempotent. Safe to re-run with `bin/rails db:seed`.

password = ENV.fetch("ADMIN_SEED_PASSWORD", "denshe-admin-123")

[
  { name: "Neshma", email: "neshma@denshe.in", role: :super_admin },
  { name: "Devanshi", email: "devanshi@denshe.in", role: :admin }
].each do |attrs|
  AdminUser.find_or_create_by!(email: attrs[:email]) do |user|
    user.name = attrs[:name]
    user.role = attrs[:role]
    user.password = password
    user.password_confirmation = password
  end
end

[
  [ "Earrings", 1 ],
  [ "Necklaces", 2 ],
  [ "Rings", 3 ],
  [ "Bracelets", 4 ],
  [ "Sets", 5 ],
  [ "Other", 6 ]
].each do |name, position|
  Category.find_or_create_by!(name: name) do |category|
    category.position = position
  end
end
