ActiveAdmin.register Coupon do
  menu parent: "Sales", priority: 4

  permit_params :code, :percent, :uses_per_customer, :customer_id, :valid_until, :active

  index do
    selectable_column
    id_column
    column :code
    column("Discount") { |coupon| coupon.percent_label }
    column("Customer") { |coupon| coupon.customer&.name || "Any shopper" }
    column("Uses per shopper", &:uses_per_customer)
    column("Valid till", &:valid_until)
    column :active
    actions
  end

  filter :code
  filter :valid_until
  filter :active

  show do
    attributes_table do
      row :code
      row("Discount") { |coupon| coupon.percent_label }
      row("Customer") { |coupon| coupon.customer || "Any shopper" }
      row("Times each shopper can use it", &:uses_per_customer)
      row("Valid till") { |coupon| coupon.valid_until || "Open" }
      row :active
      row :created_at
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :code, hint: "What the shopper types on the bag page. Letters, numbers, and hyphens."
      f.input :percent, label: "Discount %", hint: "Taken off the pieces. 10 means 10% off. Shipping stays as it is.", input_html: { min: 0.01, max: 100, step: 0.01 }
      f.input :customer, collection: Customer.order(:name), include_blank: "Any shopper", hint: "Leave this as any shopper when anyone may use the code. Choose a customer to keep the code for them."
      f.input :uses_per_customer, label: "Times each shopper can use it", hint: "1 means one order per phone number or email. A later order with the same details is refused.", input_html: { min: 1, max: 100, step: 1 }
      f.input :valid_until, as: :string, label: "Valid till", hint: "Leave blank to keep the code open. The last day is included.", input_html: { type: "date", value: f.object.valid_until&.iso8601 }
      f.input :active, hint: "Turn this off to stop the code without deleting it."
    end
    f.actions
  end
end