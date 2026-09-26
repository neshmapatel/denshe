# Celestia receipt 10082 — 19 Sept 2026. 39 unique designs, 1 piece each.

supplier = Supplier.find_or_initialize_by(name: "Celestia")
supplier.assign_attributes(
  phone: "6356496735",
  website: "https://www.celestiajewels.com",
  notes: "Online supplier (celestiajewels.com). Support +91 63564 96735. Paid by UPI on receipt 10082."
)
supplier.save!

purchase = Purchase.find_or_initialize_by(reference: "CL-10082")
purchase.assign_attributes(
  supplier: supplier,
  funded_by: Investor.find_by(name: "Neshma"),
  purchased_on: Date.new(2026, 9, 19),
  article_count: 39,
  merchandise_total: 1350,
  courier_charge: 120,
  tax_amount: 40.50,
  total_amount: 1510.50,
  notes: "Payment receipt 10082. UPI to neshmapatel1399@okhdfcbank. Subtotal ₹1,350 + shipping ₹120 + GST ₹40.50."
)
purchase.save!

items = [
  { name: "The Delicate Wish Silver-Tone Fashion Earrings", price: 40, category: "Earrings", colour: "silver" },
  { name: "The Charming Dream Anti-Tarnish Jewellery Necklace Set", price: 90, category: "Sets", material: "Anti-tarnish" },
  { name: "C-604-Mimi-0060", price: 28, category: "Earrings" },
  { name: "D-Mimi-0391", price: 30, category: "Earrings" },
  { name: "The Enchanted Love Anti-Tarnish Fashion Earrings", price: 40, category: "Earrings", material: "Anti-tarnish" },
  { name: "The Celestial Symphony Fashion Earrings", price: 32, category: "Earrings" },
  { name: "Cherry (0128)", price: 18, category: "Earrings" },
  { name: "The Glamorous Serenade Fashion Earrings", price: 30, category: "Earrings" },
  { name: "Fancy Earring (0092)", price: 17, category: "Earrings" },
  { name: "The Modern Delight Anti-Tarnish Adjustable Fashion Ring", price: 40, category: "Rings", material: "Anti-tarnish" },
  { name: "The Aurora Spark Anti-Tarnish Adjustable Fashion Ring", price: 40, category: "Rings", material: "Anti-tarnish" },
  { name: "The Dazzling Desire Anti-Tarnish Adjustable Fashion Ring", price: 40, category: "Rings", material: "Anti-tarnish" },
  { name: "The Dreamy Delight Anti-Tarnish Adjustable Fashion Ring", price: 50, category: "Rings", material: "Anti-tarnish" },
  { name: "The Charming Grace Anti-Tarnish Adjustable Fashion Ring", price: 40, category: "Rings", material: "Anti-tarnish" },
  { name: "The Regal Grace Anti-Tarnish Adjustable Fashion Ring", price: 50, category: "Rings", material: "Anti-tarnish" },
  { name: "The Sunlit Story Anti-Tarnish Adjustable Fashion Ring", price: 40, category: "Rings", material: "Anti-tarnish" },
  { name: "The Charming Desire Anti-Tarnish Pendant Necklace", price: 90, category: "Combo", material: "Anti-tarnish" },
  { name: "D-Mimi-0073", price: 28, category: "Earrings" },
  { name: "The Chic Treasure Fashion Earrings", price: 28, category: "Earrings" },
  { name: "The Twilight Noor Fashion Earrings", price: 36, category: "Earrings" },
  { name: "The Moonlit Beauty Fashion Earrings", price: 30, category: "Earrings" },
  { name: "The Enchanted Grace Fashion Earrings", price: 15, category: "Earrings" },
  { name: "C-604-MIMI-0433", price: 24, category: "Earrings" },
  { name: "D-Mimi-0319", price: 24, category: "Earrings" },
  { name: "The Shimmering Radiance Fashion Earrings", price: 24, category: "Earrings" },
  { name: "The Graceful Symphony Fashion Earrings", price: 28, category: "Earrings" },
  { name: "The Velvet Serenade Fashion Earrings", price: 28, category: "Earrings" },
  { name: "The Luminous Spark Fashion Earrings", price: 32, category: "Earrings" },
  { name: "Golden Leaf Vein Earrings", price: 28, category: "Earrings", colour: "gold" },
  { name: "D-604-Mimi-0001", price: 28, category: "Earrings" },
  { name: "D-Mimi-0146 AND 0029 (Golden)", price: 28, category: "Earrings", colour: "gold" },
  { name: "D-Mimi-0095", price: 32, category: "Earrings" },
  { name: "C-604-Mimi-0048", price: 32, category: "Earrings" },
  { name: "D-Mimi-0030", price: 33, category: "Earrings" },
  { name: "Korean Earring (0468)", price: 16, category: "Earrings" },
  { name: "C-Mimi-0028 (0035) black", price: 45, category: "Earrings", colour: "black" },
  { name: "D-Mimi-0071", price: 28, category: "Earrings" },
  { name: "The Serene Aura Fashion Earrings", price: 32, category: "Earrings" },
  { name: "Mimi-0423 (0042)", price: 36, category: "Earrings" }
]

items.each_with_index do |item, index|
  sku = format("CL-10082-%03d", index + 1)
  category = Category.find_by!(name: item[:category])

  product = Product.find_or_initialize_by(sku: sku)
  product.assign_attributes(
    category: category,
    supplier: supplier,
    purchase: purchase,
    name: item[:name],
    purchase_price: item[:price],
    selling_price: product.selling_price.presence || 0,
    stock_quantity: product.persisted? ? product.stock_quantity : 1,
    quantity_purchased: product.persisted? ? product.quantity_purchased : 1,
    low_stock_threshold: 0,
    colour: item[:colour],
    material: item[:material],
    status: product.persisted? ? product.status : :draft,
    short_description: "From Celestia receipt 10082. Update details when the piece arrives.",
    opening_stock_reason: "Purchased from Celestia — CL-10082"
  )
  product.save!
end
