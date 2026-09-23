ActiveAdmin.register Purchase do
  extend SearchableAdmin

  menu parent: "Sourcing", priority: 2
  searchable placeholder: "Search lot reference or supplier"

  permit_params :supplier_id, :funded_by_id, :reference, :purchased_on, :article_count,
                :merchandise_total, :courier_charge, :tax_amount, :total_amount, :notes

  index do
    selectable_column
    id_column
    column :reference
    column :supplier
    column :funded_by
    column :purchased_on
    column :article_count
    column("Merchandise") { |purchase| "₹#{purchase.merchandise_total}" }
    column("Courier") { |purchase| "₹#{purchase.courier_charge}" }
    column("Tax") { |purchase| "₹#{purchase.tax_amount}" }
    column("Total") { |purchase| "₹#{purchase.total_amount}" }
    actions
  end

  filter :supplier
  filter :funded_by
  filter :purchased_on

  show do
    attributes_table do
      row :reference
      row :supplier
      row :funded_by
      row :purchased_on
      row :article_count
      row(:merchandise_total) { |purchase| "₹#{purchase.merchandise_total}" }
      row(:courier_charge) { |purchase| "₹#{purchase.courier_charge}" }
      row(:tax_amount) { |purchase| "₹#{purchase.tax_amount}" }
      row(:total_amount) { |purchase| "₹#{purchase.total_amount}" }
      row(:landed_cost_per_article) { |purchase| "₹#{purchase.landed_cost_per_article}" }
      row :notes
    end

    panel "Articles in this lot" do
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
    f.inputs "Purchase lot" do
      f.input :supplier
      f.input :funded_by, label: "Paid by"
      f.input :reference, hint: "Your internal lot number, e.g. MV-LOT-001"
      f.input :purchased_on, as: :date_picker, hint: "Date you bought this lot."
      f.input :article_count
      f.input :merchandise_total, label: "Merchandise total (articles only)"
      f.input :courier_charge, label: "Courier / shipping"
      f.input :tax_amount, label: "GST / tax"
      f.input :total_amount, hint: "Merchandise plus courier plus tax"
      f.input :notes
    end
    f.actions
  end
end
