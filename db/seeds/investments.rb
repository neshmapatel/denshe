neshma = Investor.find_by!(name: "Neshma")

[
  {
    reference: "MV-LOT-001",
    notes: "Neshma paid the Mahavir Enterprise lot in full, including courier."
  },
  {
    reference: "CL-10082",
    notes: "Neshma paid the Celestia receipt in full, including shipping and GST."
  }
].each do |attrs|
  purchase = Purchase.find_by!(reference: attrs[:reference])
  purchase.update!(funded_by: neshma)

  investment = Investment.find_or_initialize_by(investor: neshma, purchase: purchase)
  investment.assign_attributes(
    amount: purchase.total_amount,
    kind: :product_purchase,
    invested_on: purchase.purchased_on,
    notes: attrs[:notes]
  )
  investment.save!
end
