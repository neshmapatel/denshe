ActiveAdmin.register Payment do
  menu parent: "Sales", priority: 2

  actions :index, :show

  includes :order, :payment_gateway

  index do
    id_column
    column(:order) { |payment| link_to payment.order.number, admin_order_path(payment.order) }
    column(:gateway) { |payment| payment.payment_gateway.name }
    column :status
    column("Amount") { |payment| "₹#{payment.amount}" }
    column :error_message
    column :created_at
    actions
  end

  filter :status
  filter :error_code
  filter :created_at

  show do
    attributes_table do
      row :order
      row :payment_gateway
      row :status
      row(:amount) { |payment| "₹#{payment.amount}" }
      row :currency
      row :gateway_order_id
      row :gateway_payment_id
      row :error_code
      row :error_message
      row :error_source
      row :error_step
      row :error_reason
      row :created_at
    end
  end
end
