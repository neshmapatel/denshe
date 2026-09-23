ActiveAdmin.register Address do
  extend SearchableAdmin

  menu parent: "Sales", priority: 4
  searchable placeholder: "Search name, city, PIN, or customer"

  permit_params :customer_id, :name, :phone, :line1, :line2, :city, :state, :pin_code, :country, :kind

  index do
    selectable_column
    id_column
    column :customer
    column :kind
    column :line1
    column :city
    column :state
    column :pin_code
    actions
  end

  filter :customer
  filter :city
  filter :state
  filter :kind
end
