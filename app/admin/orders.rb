ActiveAdmin.register Order do
  extend SearchableAdmin

  menu parent: "Sales", priority: 1
  searchable placeholder: "Search order number, customer, or email"

  permit_params :customer_id, :new_customer_name, :new_customer_email, :new_customer_phone,
                :shipping_address_id, :billing_address_id, :order_type,
                :status, :subtotal, :shipping_amount, :discount, :total, :payment_status,
                :payment_reference, :payment_method, :shipping_status, :guest_name,
                :guest_email, :guest_phone, :customer_notes, :admin_notes

  action_item :collect_cash, only: :show, if: -> { !resource.payment_paid? } do
    link_to "Collected in cash", collect_cash_admin_order_path(resource), method: :post
  end

  action_item :gift_by_owner, only: :show, if: -> { !resource.payment_paid? } do
    link_to "Gifted by the owner", gift_by_owner_admin_order_path(resource), method: :post
  end

  member_action :collect_cash, method: :post do
    resource.collect_cash!
    redirect_to resource_path, notice: "Collected in cash and marked as paid."
  rescue ArgumentError => error
    redirect_to resource_path, alert: error.message
  end

  member_action :gift_by_owner, method: :post do
    resource.gift_by_owner!
    redirect_to resource_path, notice: "Marked as paid. Gifted by the owner."
  rescue ArgumentError => error
    redirect_to resource_path, alert: error.message
  end

  scope :all, default: true
  scope :pending
  scope :paid
  scope :processing
  scope :shipped
  scope :delivered
  scope :cancelled
  scope("Mystery boxes") { |orders| orders.mystery_box }
  scope("Australia") { |orders| orders.where(currency: "AUD") }

  controller do
    def scoped_collection
      super.includes(:customer, order_items: :product)
    end

    def build_new_resource
      order = super
      customer = Customer.find_by(id: params[:customer_id]) if params[:customer_id].present?
      if customer
        order.customer = customer
        order.guest_name = customer.name
        order.guest_email = customer.email
        order.guest_phone = customer.phone
      end
      order
    end
  end

  index do
    selectable_column
    id_column
    column :number
    column("Customer", &:customer_display_name)
    column("Products") { |order| order.order_items.map { |item| item.product&.name || item.name }.join(", ") }
    column :order_type
    column :status
    column :payment_status
    column("Total") { |order| order.money(order.total) }
    column :created_at
    actions
  end

  filter :status
  filter :payment_status
  filter :order_type
  filter :currency
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
      row("Payment") { |order| order.payment_label }
      row :payment_reference
      row :shipping_status
      row :currency
      row(:subtotal) { |order| order.money(order.subtotal) }
      row(:shipping_amount) { |order| order.money(order.shipping_amount) }
      row(:coupon_code)
      row(:voucher_name)
      row(:discount) { |order| order.money(order.discount) }
      row(:total) { |order| order.money(order.total) }
      row :customer_notes
      row :admin_notes
      row :created_at
    end

    panel "Payments" do
      if resource.payments.any?
        table_for resource.payments.order(created_at: :desc) do
          column(:gateway) { |payment| payment.payment_gateway.name }
          column :status
          column("Amount") { |payment| "₹#{payment.amount}" }
          column :gateway_order_id
          column :gateway_payment_id
          column :error_code
          column :error_message
          column :created_at
        end
      else
        para "No payment attempts yet."
      end
    end

    panel "Items" do
      table_for resource.order_items.includes(:product) do
        column("Product") do |item|
          if item.product
            link_to item.product.name, admin_product_path(item.product)
          else
            item.name
          end
        end
        column :item_type
        column :sku
        column :quantity
        column("Unit price") { |item| resource.money(item.unit_price) }
        column("Line total") { |item| resource.money(item.line_total) }
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
    f.inputs "Customer" do
      f.input :customer, collection: Customer.order(:name), include_blank: "Choose a customer"
      f.input :new_customer_name, as: :string, label: "Or add a new customer", hint: "Name, email, and phone. Leave these blank when you chose someone above."
      f.input :new_customer_email, as: :string, label: "New customer email"
      f.input :new_customer_phone, as: :string, label: "New customer phone"
      f.input :guest_name
      f.input :guest_email
      f.input :guest_phone
    end
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
