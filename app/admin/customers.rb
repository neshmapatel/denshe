ActiveAdmin.register Customer do
  extend SearchableAdmin

  menu parent: "Sales", priority: 2
  searchable placeholder: "Search name, email, or phone"

  permit_params :name, :email, :phone

  index do
    selectable_column
    id_column
    column :name
    column :email
    column :phone
    column("Orders") { |customer| customer.orders.count }
    actions
  end

  filter :created_at

  show do
    attributes_table do
      row :name
      row :email
      row :phone
      row :created_at
    end

    panel "Addresses" do
      table_for resource.addresses do
        column :kind
        column :line1
        column :city
        column :state
        column :pin_code
      end
    end

    panel "Orders" do
      table_for resource.orders.newest_first do
        column(:number) { |order| link_to order.to_s, admin_order_path(order) }
        column :status
        column :total
        column :created_at
      end
    end
  end
end
