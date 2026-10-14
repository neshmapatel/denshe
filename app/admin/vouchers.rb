ActiveAdmin.register Voucher do
  menu parent: "Sales", priority: 5

  permit_params :name, :minimum_spend, :percent, :discount_amount, :active, :starts_on, :ends_on

  index do
    selectable_column
    id_column
    column :name
    column("Spend") { |voucher| "₹#{voucher.minimum_spend}" }
    column("Off") { |voucher| voucher.offer_label || "₹#{voucher.discount_amount}" }
    column :starts_on
    column :ends_on
    column :active
    actions
  end

  filter :name
  filter :active
  filter :starts_on
  filter :ends_on

  show do
    attributes_table do
      row :name
      row("Minimum spend") { |voucher| "₹#{voucher.minimum_spend}" }
      row("Percent off") { |voucher| voucher.offer_label || "—" }
      row("Amount off") { |voucher| voucher.discount_amount.to_d.positive? ? "₹#{voucher.discount_amount}" : "—" }
      row :starts_on
      row :ends_on
      row :active
      row :created_at
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :name, hint: "Shown on the bag when the offer applies. The shopper does not enter a code."
      f.input :minimum_spend, label: "When the order reaches", hint: "The offer applies on its own once the pieces add up to this amount.", input_html: { min: 0, max: 999_999, step: 0.01 }
      f.input :percent, label: "Percent off", hint: "5 means 5% off the pieces. For example, 5% once the order reaches ₹599. Shipping stays as it is.", input_html: { min: 0.01, max: 100, step: 0.01 }
      f.input :discount_amount, label: "Or amount off", hint: "Rupees taken off, when you are not using a percent. Leave this at 0 for a percent offer.", input_html: { min: 0, max: 999_999, step: 0.01 }
      f.input :starts_on, label: "Activate on", hint: "Leave blank to start as soon as Active is on."
      f.input :ends_on, label: "Deactivate on", hint: "Leave blank to keep it on until you turn Active off. The last day is included."
      f.input :active, hint: "Turn this off to stop the offer immediately. Turn it on again when it should apply."
    end
    f.actions
  end
end