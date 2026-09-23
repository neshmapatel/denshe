ActiveAdmin.register AdminUser do
  extend SearchableAdmin

  menu label: "Admin users", priority: 20
  searchable placeholder: "Search name or email"

  permit_params :name, :email, :role, :password, :password_confirmation

  index do
    selectable_column
    id_column
    column :name
    column :email
    column :role
    column :created_at
    actions
  end

  filter :role
  filter :created_at

  show do
    attributes_table do
      row :id
      row :name
      row :email
      row :role
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs "Admin account" do
      f.input :name
      f.input :email
      f.input :role, as: :select, collection: AdminUser.roles.keys
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end
end
