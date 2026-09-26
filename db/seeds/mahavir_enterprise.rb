# Temporary names until the physical pieces arrive.

supplier = Supplier.find_or_create_by!(name: "Mahavir Enterprise") do |record|
  record.phone = "8169946997"
  record.area = "Malad"
  record.city = "Mumbai"
  record.state = "Maharashtra"
end
supplier.update!(
  phone: "8169946997",
  area: "Malad",
  city: "Mumbai",
  state: "Maharashtra"
)

purchase = Purchase.find_or_initialize_by(reference: "MV-LOT-001")
purchase.assign_attributes(
  supplier: supplier,
  funded_by: Investor.find_by(name: "Neshma"),
  purchased_on: Date.new(2026, 9, 20),
  article_count: 62,
  merchandise_total: 5170,
  courier_charge: 80,
  tax_amount: 0,
  total_amount: 5250,
  notes: "62 unique articles. Courier ₹80. Temporary product names — update when the pieces arrive."
)
purchase.save!

lot = [
  {
    category: "Kadas",
    sku_prefix: "MV-KDA",
    colour: "gold",
    material: "Metal",
    lines: [
      { unit_price: 100, names: [
        "Golden Kada",
        "Textured Golden Kada",
        "Classic Golden Kada",
        "Slim Golden Kada",
        "Polished Golden Kada"
      ] },
      { unit_price: 180, names: [
        "Heavy Golden Kada",
        "Ornate Golden Kada",
        "Statement Golden Kada"
      ] },
      { unit_price: 160, names: [
        "Twisted Golden Kada",
        "Carved Golden Kada"
      ] },
      { unit_price: 120, names: [
        "Everyday Golden Kada"
      ] }
    ]
  },
  {
    category: "Bracelets",
    sku_prefix: "MV-BRC",
    colour: "gold",
    material: "AD / American diamond",
    lines: [
      { unit_price: 40, names: [
        "AD Tennis Bracelet",
        "AD Link Bracelet"
      ] },
      { unit_price: 30, names: [
        "Delicate AD Bracelet",
        "Minimal AD Bracelet"
      ] }
    ]
  },
  {
    category: "Combo",
    sku_prefix: "MV-ATN",
    colour: "gold",
    material: "Anti-tarnish",
    lines: [
      { unit_price: 110, names: [
        "Anti-tarnish Bangle",
        "Anti-tarnish Coil Bangle",
        "Anti-tarnish Open Cuff",
        "Anti-tarnish Stack Bangle",
        "Anti-tarnish Sleek Bangle"
      ] }
    ]
  },
  {
    category: "Handchains",
    sku_prefix: "MV-HCH",
    colour: "gold",
    material: "Metal",
    lines: [
      { unit_price: 120, names: [
        "Golden Handchain",
        "Delicate Golden Handchain",
        "Twisted Golden Handchain"
      ] }
    ]
  },
  {
    category: "Chain Pendants",
    sku_prefix: "MV-CHN",
    colour: "gold",
    material: "Metal",
    lines: [
      { unit_price: 100, names: [ "Golden Pendant Chain" ] },
      { unit_price: 90, names: [
        "Dainty Golden Pendant Chain",
        "Oval Pendant Chain",
        "Heart Pendant Chain",
        "Coin Pendant Chain",
        "Round Pendant Chain",
        "Bar Pendant Chain",
        "Leaf Pendant Chain",
        "Drop Pendant Chain"
      ] },
      { unit_price: 80, names: [
        "Slim Golden Chain",
        "Everyday Pendant Chain",
        "Classic Pendant Chain",
        "Minimal Pendant Chain",
        "Layering Pendant Chain",
        "Short Pendant Chain",
        "Long Pendant Chain",
        "Fine Pendant Chain",
        "Polished Pendant Chain",
        "Simple Pendant Chain",
        "Open Circle Pendant Chain",
        "Teardrop Pendant Chain",
        "Petite Pendant Chain"
      ] },
      { unit_price: 70, names: [
        "Curved Pendant Chain",
        "Soft Link Pendant Chain"
      ] },
      { unit_price: 65, names: [
        "Whisper Pendant Chain",
        "Light Pendant Chain",
        "Airy Pendant Chain"
      ] },
      { unit_price: 60, names: [
        "Bare Golden Chain",
        "Thin Pendant Chain"
      ] }
    ]
  },
  {
    category: "Earrings",
    sku_prefix: "MV-EAR",
    colour: "gold",
    material: "Anti-tarnish",
    lines: [
      { unit_price: 35, names: [
        "Anti-tarnish Golden Hoops",
        "Anti-tarnish Twisted Hoops",
        "Anti-tarnish Small Hoops",
        "Anti-tarnish Bali Earrings",
        "Anti-tarnish Drop Earrings"
      ] },
      { unit_price: 30, names: [
        "Anti-tarnish Stud Earrings",
        "Anti-tarnish Mini Studs",
        "Anti-tarnish Disc Earrings",
        "Anti-tarnish Tiny Hoops",
        "Anti-tarnish Circle Studs"
      ] }
    ]
  }
]

sku_sequence = Hash.new(0)

lot.each do |group|
  category = Category.find_by!(name: group[:category])

  group[:lines].each do |line|
    line[:names].each do |name|
      sku_sequence[group[:sku_prefix]] += 1
      sku = format("%s-%03d", group[:sku_prefix], sku_sequence[group[:sku_prefix]])

      product = Product.find_or_initialize_by(sku: sku)
      product.assign_attributes(
        category: category,
        supplier: supplier,
        purchase: purchase,
        name: name,
        purchase_price: line[:unit_price],
        selling_price: product.selling_price.presence || 0,
        stock_quantity: product.persisted? ? product.stock_quantity : 1,
        quantity_purchased: product.persisted? ? product.quantity_purchased : 1,
        low_stock_threshold: 0,
        colour: group[:colour],
        material: group[:material],
        status: product.persisted? ? product.status : :draft,
        short_description: "Temporary name from the Mahavir Enterprise lot. Update when the piece arrives.",
        opening_stock_reason: "Purchased from Mahavir Enterprise — MV-LOT-001"
      )
      product.save!
    end
  end
end
