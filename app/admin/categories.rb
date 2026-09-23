ActiveAdmin.register Category do
  extend SearchableAdmin

  menu parent: "Catalogue", priority: 1
  searchable placeholder: "Search name or slug"

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

  show do
    attributes_table do
      row :name
      row :slug
      row :position
      row("Products") { |category| category.products.count }
    end

    panel "Search #{resource.name.downcase}" do
      text_node helpers.admin_search_bar(
        url: admin_category_path(resource),
        placeholder: "Search name, SKU, or slug"
      )

      products = resource.products.search(params[:search]).order(:name)
      if products.any?
        table_for products do
          column(:name) { |product| link_to product.name, admin_product_path(product) }
          column :sku
          column :slug
          column :status
          column("Stock", &:stock_quantity)
          column("Selling") { |product| "₹#{product.selling_price}" }
        end
      else
        para params[:search].present? ? "No products match that search." : "No products in this category yet."
      end
    end
  end

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
