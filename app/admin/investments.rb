ActiveAdmin.register Investment do
  extend SearchableAdmin

  menu parent: "Finance", priority: 2
  searchable placeholder: "Search investor, lot, or note"

  permit_params :investor_id, :purchase_id, :amount, :kind, :invested_on, :notes

  index do
    selectable_column
    id_column
    column :investor
    column :kind
    column(:amount) { |investment| "₹#{investment.amount}" }
    column :purchase
    column :invested_on
    actions
  end

  filter :investor
  filter :kind
  filter :purchase
  filter :invested_on

  form do |f|
    f.semantic_errors
    f.inputs "Investment" do
      f.input :investor
      f.input :kind
      f.input :amount
      f.input :purchase
      f.input :invested_on, as: :date_picker
      f.input :notes
    end
    f.actions
  end
end
