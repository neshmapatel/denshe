ActiveAdmin.register Order do
  menu parent: "Sales", priority: 1

  permit_params :customer_id, :shipping_address_id, :billing_address_id, :order_type,
                :status, :subtotal, :shipping_amount, :discount, :total, :payment_status,
                :payment_reference, :payment_method, :shipping_status, :guest_name,
                :guest_email, :guest_phone, :customer_notes, :admin_notes

  scope :all, default: true
  scope :pending
  scope :paid
  scope :processing
  scope :shipped
  scope :delivered
  scope :cancelled
  scope("Mystery boxes") { |orders| orders.mystery_box }

  index do
    selectable_column
    id_column
    column :number
    column("Customer", &:customer_display_name)
    column :order_type
    column :status
    column :payment_status
    column("Total") { |order| "₹#{order.total}" }
    column :created_at
    actions
  end

  filter :number
  filter :status
  filter :payment_status
  filter :order_type
  filter :created_at

  show do
    attributes_table do
      row :number
      row :order_type
      row :status
      row :customer
      row("Guest name", &:guest_name)
      row("Guest email", &:guest_email)
      row("Guest phone", &:guest_phone)
      row :shipping_address
      row :payment_status
      row :payment_method
      row :payment_reference
      row :shipping_status
      row(:subtotal) { |order| "₹#{order.subtotal}" }
      row(:shipping_amount) { |order| "₹#{order.shipping_amount}" }
      row(:discount) { |order| "₹#{order.discount}" }
      row(:total) { |order| "₹#{order.total}" }
      row :customer_notes
      row :admin_notes
      row :created_at
    end

    panel "Items" do
      table_for resource.order_items do
        column :name
        column :sku
        column :quantity
        column("Unit price") { |item| "₹#{item.unit_price}" }
        column("Line total") { |item| "₹#{item.line_total}" }
      end
    end

    if resource.mystery_box_preference
      panel "Mystery box answers" do
        attributes_table_for resource.mystery_box_preference do
          resource.mystery_box_preference.summary_lines.each do |label, value|
            row(label) { value }
          end
        end
      end
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs "Fulfilment" do
      f.input :status
      f.input :payment_status
      f.input :shipping_status
      f.input :payment_reference
      f.input :payment_method
      f.input :admin_notes
    end
    f.actions
  end
end
