ActiveAdmin.register Category do
  menu parent: "Catalogue", priority: 1

  permit_params :name, :slug, :position

  config.sort_order = "position_asc"

  index do
    selectable_column
    id_column
    column :name
    column :slug
    column :position
    column("Products") { |category| category.products.count }
    actions
  end

  filter :name
  filter :slug

  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :name
      f.input :slug, hint: "Leave blank to generate from the name."
      f.input :position
    end
    f.actions
  end
end
