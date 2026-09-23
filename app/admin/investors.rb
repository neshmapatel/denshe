ActiveAdmin.register Investor do
  extend SearchableAdmin

  menu parent: "Finance", priority: 1
  searchable placeholder: "Search name or email"

  permit_params :name, :email, :admin_user_id, :notes

  index do
    selectable_column
    id_column
    column :name
    column :email
    column("Invested") { |investor| "₹#{investor.total_invested}" }
    actions
  end

  filter :created_at

  show do
    attributes_table do
      row :name
      row :email
      row :admin_user
      row(:total_invested) { |investor| "₹#{investor.total_invested}" }
      row :notes
    end

    panel "Investments" do
      table_for resource.investments.order(invested_on: :desc) do
        column(:invested_on)
        column(:kind)
        column(:amount) { |investment| "₹#{investment.amount}" }
        column(:purchase)
        column(:notes)
      end
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs "Investor" do
      f.input :name
      f.input :email
      f.input :admin_user
      f.input :notes
    end
    f.actions
  end
end
