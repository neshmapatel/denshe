ActiveAdmin.register Supplier do
  extend SearchableAdmin

  menu parent: "Sourcing", priority: 1
  searchable placeholder: "Search name, phone, or city"

  permit_params :name, :phone, :website, :area, :city, :state, :pin_code, :notes

  index do
    selectable_column
    id_column
    column :name
    column :phone
    column :website
    column(:location, &:location)
    column("Purchases") { |supplier| supplier.purchases.count }
    column("Products") { |supplier| supplier.products.count }
    actions
  end

  filter :city

  show do
    attributes_table do
      row :name
      row :phone
      row :website
      row :area
      row :city
      row :state
      row :pin_code
      row :notes
    end

    panel "Purchases" do
      table_for resource.purchases.order(purchased_on: :desc) do
        column(:reference) { |purchase| link_to purchase.reference, admin_purchase_path(purchase) }
        column :purchased_on
        column :article_count
        column("Merchandise") { |purchase| "₹#{purchase.merchandise_total}" }
        column("Courier") { |purchase| "₹#{purchase.courier_charge}" }
        column("Total") { |purchase| "₹#{purchase.total_amount}" }
      end
    end

    panel "Products" do
      table_for resource.products.includes(:category).order(:sku) do
        column(:sku) { |product| link_to product.sku, admin_product_path(product) }
        column :name
        column :category
        column("Purchase") { |product| "₹#{product.purchase_price}" }
        column :stock_quantity
        column :status
      end
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs "Supplier" do
      f.input :name
      f.input :phone
      f.input :website
      f.input :area, hint: "Neighbourhood, e.g. Malad"
      f.input :city
      f.input :state
      f.input :pin_code
      f.input :notes
    end
    f.actions
  end
end
