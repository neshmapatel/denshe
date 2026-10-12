ActiveAdmin.register Voucher do
  menu parent: "Sales", priority: 5

  permit_params :name, :minimum_spend, :discount_amount, :active, :starts_on, :ends_on

  index do
    selectable_column
    id_column
    column :name
    column("Spend") { |voucher| "₹#{voucher.minimum_spend}" }
    column("Off") { |voucher| "₹#{voucher.discount_amount}" }
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
      row("Amount off") { |voucher| "₹#{voucher.discount_amount}" }
      row :starts_on
      row :ends_on
      row :active
      row :created_at
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :name, hint: "Shown on the bag when the offer applies. For example, Festive ₹200."
      f.input :minimum_spend, label: "When the order reaches", hint: "The offer applies on its own once the pieces add up to this amount.", input_html: { min: 0, max: 999_999, step: 0.01 }
      f.input :discount_amount, label: "Amount off", hint: "Rupees taken off. It does not change the shipping line.", input_html: { min: 0.01, max: 999_999, step: 0.01 }
      f.input :starts_on, label: "Activate on", hint: "Leave blank to start as soon as Active is on."
      f.input :ends_on, label: "Deactivate on", hint: "Leave blank to keep it on until you turn Active off. The last day is included."
      f.input :active, hint: "Turn this off to stop the offer immediately. Turn it on again when it should apply."
    end
    f.actions
  end
end