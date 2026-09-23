require "test_helper"

class SupplierTest < ActiveSupport::TestCase
  test "stores supplier contact and location" do
    supplier = Supplier.create!(
      name: "Mahavir Enterprise",
      phone: "8169946997",
      area: "Malad",
      city: "Mumbai",
      state: "Maharashtra"
    )

    assert_equal "Malad, Mumbai, Maharashtra", supplier.location
    supplier.update!(website: "https://example.com")
    assert_equal "https://example.com", supplier.website
  end
end
