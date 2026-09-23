class AddTaxAndSupplierWebsiteToPurchases < ActiveRecord::Migration[8.1]
  def change
    add_column :purchases, :tax_amount, :decimal, precision: 10, scale: 2, null: false, default: 0
    add_column :suppliers, :website, :string
  end
end
