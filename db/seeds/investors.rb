[
  {
    name: "Neshma",
    email: "neshma@denshe.in",
    notes: "Has paid for all product lots and purchase expenses so far."
  },
  {
    name: "Devanshi",
    email: "devanshi@denshe.in",
    notes: "Co-founder. No capital contributed yet."
  }
].each do |attrs|
  investor = Investor.find_or_initialize_by(name: attrs[:name])
  investor.assign_attributes(
    email: attrs[:email],
    admin_user: AdminUser.find_by(email: attrs[:email]),
    notes: attrs[:notes]
  )
  investor.save!
end
