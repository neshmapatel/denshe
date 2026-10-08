ActiveAdmin.register Combo do
  menu parent: "Catalogue", priority: 3

  permit_params :name, :slug, :price, :short_description, :description, :status, :position,
                groups_attributes: [ :id, :name, :choose_count, :position, :_destroy, { selected_product_ids: [] } ]

  config.sort_order = "position_asc"

  index do
    selectable_column
    id_column
    column :name
    column(:price) { |combo| "₹#{combo.price}" }
    column :status
    column("Shopper picks") { |combo| combo.choice_summary.presence || "—" }
    actions
  end

  filter :name
  filter :status
  filter :price

  show do
    attributes_table do
      row :name
      row :slug
      row(:price) { |combo| "₹#{combo.price}" }
      row :status
      row :position
      row :short_description
      row :description
    end

    resource.groups.includes(options: :product).each do |group|
      panel "#{group.name} — shopper picks #{group.choose_count}" do
        if group.products.any?
          table_for group.products do
            column(:name) { |product| link_to product.name, admin_product_path(product) }
            column :status
            column("Stock", &:stock_quantity)
          end
        else
          para "No pieces in this choice yet."
        end
      end
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs "Combo" do
      f.input :name
      f.input :slug, hint: "Leave blank to generate from the name."
      f.input :price, label: "Price (₹)", hint: "What the shopper pays for the whole combo, whichever pieces they pick."
      f.input :status, include_blank: false
      f.input :position
      f.input :short_description
      f.input :description
    end

    f.inputs "Choices" do
      para "Add one choice per group, such as earrings or necklaces. Set how many pieces the shopper can pick from that group, then choose which pieces they may pick from."
      f.has_many :groups, heading: "Choice", allow_destroy: true, new_record: "Add a choice" do |group|
        group.input :name, hint: "Earrings, necklaces, and so on."
        group.input :choose_count,
                    label: "Pieces the shopper can pick",
                    hint: "How many they pick from the list below. 1 means one necklace from these necklaces.",
                    input_html: { min: 1 }
        group.input :position
        li do
          group.template.concat(
            group.template.render(partial: "admin/combos/piece_picker", locals: { builder: group })
          )
        end
      end
    end

    f.actions

    text_node render(partial: "admin/combos/picker_script")
  end

  controller do
    helper_method :combo_piece_choices, :combo_piece_categories

    def scoped_collection
      super.includes(:groups)
    end

    def combo_piece_choices
      @combo_piece_choices ||= Product.in_stock.includes(:category).order("categories.name", "products.name").to_a
    end

    def combo_piece_categories
      @combo_piece_categories ||= combo_piece_choices.map(&:category).uniq
    end
  end
end
