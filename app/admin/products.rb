ActiveAdmin.register Product do
  extend SearchableAdmin

  menu parent: "Catalogue", priority: 2
  searchable placeholder: "Search name, SKU, or slug"

  permit_params :category_id, :name, :slug, :sku, :description, :short_description,
                :purchase_price, :selling_price, :compare_at_price, :packaging_allocation,
                :shipping_allocation, :gst_rate, :quantity_purchased, :stock_quantity,
                :low_stock_threshold, :material, :colour, :dimensions, :weight,
                :care_instructions, :whats_included, :status, :featured, :new_arrival,
                :bestseller, :meta_title, :meta_description, images: []

  scope :all, default: true
  scope :earrings
  scope :active
  scope :draft
  scope :archived
  scope :low_stock
  scope :out_of_stock

  index title: -> { params[:search].present? ? "Products matching “#{params[:search]}”" : "Products" } do
    selectable_column
    id_column
    column :name
    column :sku
    column :slug
    column :category
    column :status
    column("Purchase") { |product| "₹#{product.purchase_price}" }
    column("Selling") { |product| "₹#{product.selling_price}" }
    column("Stock", &:stock_quantity)
    column("Purchased", &:quantity_purchased)
    column("Sold", &:sold_quantity)
    actions
  end

  filter :category
  filter :status
  filter :featured
  filter :new_arrival
  filter :bestseller

  show do
    attributes_table do
      row :name
      row :slug
      row :sku
      row :category
      row :status
      row :featured
      row :new_arrival
      row :bestseller
      row :short_description
      row :description
    end

    panel "Pricing (admin only — purchase price is never shown to customers)" do
      attributes_table_for resource do
        row(:purchase_price) { |product| "₹#{product.purchase_price}" }
        row(:packaging_allocation) { |product| "₹#{product.packaging_allocation}" }
        row(:shipping_allocation) { |product| "₹#{product.shipping_allocation}" }
        row(:selling_price) { |product| "₹#{product.selling_price}" }
        row(:compare_at_price) { |product| product.compare_at_price ? "₹#{product.compare_at_price}" : nil }
        row(:gst_rate) { |product| product.gst_rate.present? ? "#{product.gst_rate}%" : "Not set" }
        row(:contribution_margin) { |product| "₹#{product.contribution_margin}" }
      end
    end

    panel "Inventory" do
      attributes_table_for resource do
        row("Purchased", &:quantity_purchased)
        row("Sold", &:sold_quantity)
        row("Available", &:stock_quantity)
        row :low_stock_threshold
      end

      para do
        span link_to "Add stock", new_admin_inventory_movement_path(inventory_movement: { product_id: resource.id, movement_type: "purchase" })
        text_node " · "
        span link_to "Adjust stock", new_admin_inventory_movement_path(inventory_movement: { product_id: resource.id, movement_type: "adjustment" })
        text_node " · "
        span link_to "View history", admin_inventory_movements_path(q: { product_id_eq: resource.id })
      end
    end

    panel "Details" do
      attributes_table_for resource do
        row :material
        row :colour
        row :dimensions
        row :weight
        row :whats_included
        row :care_instructions
      end
    end

    panel "SEO" do
      attributes_table_for resource do
        row :meta_title
        row :meta_description
      end
    end

    panel "Images" do
      if resource.images.attached?
        ul do
          resource.images.each do |image|
            li do
              image_tag url_for(image), width: 240
            end
          end
        end
      else
        para "No images uploaded yet."
      end
    end

    panel "Stock history" do
      table_for resource.inventory_movements.newest_first.limit(20) do
        column(:when, &:created_at)
        column(:type, &:movement_type)
        column(:quantity) { |movement| movement.quantity.positive? ? "+#{movement.quantity}" : movement.quantity }
        column(:reason)
        column(:by, &:admin_user)
      end
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs "Basic" do
      f.input :category
      f.input :name
      f.input :slug, hint: "Leave blank to generate from the name."
      f.input :sku
      f.input :short_description
      f.input :description
      f.input :status
      f.input :featured
      f.input :new_arrival, label: "New badge"
      f.input :bestseller, label: "Bestseller badge"
    end

    f.inputs "Pricing" do
      f.input :purchase_price, label: "Purchase price (what DeNshe paid)"
      f.input :packaging_allocation
      f.input :shipping_allocation
      f.input :selling_price
      f.input :compare_at_price, label: "Compare-at / MRP"
      f.input :gst_rate, hint: "Optional percent, e.g. 3 or 18. Leave blank for now."
    end

    f.inputs "Inventory" do
      f.input :quantity_purchased, hint: "Total bought from the supplier. On first save, this follows current stock if left at 0."
      f.input :stock_quantity, label: "Current stock"
      f.input :low_stock_threshold
    end

    f.inputs "Product details" do
      f.input :material
      f.input :colour
      f.input :dimensions
      f.input :weight
      f.input :whats_included
      f.input :care_instructions
    end

    f.inputs "Images" do
      f.input :images, as: :file, input_html: { multiple: true, accept: "image/*" },
                       hint: "JPEG, PNG, or WebP. Additional uploads are added to the existing gallery."
    end

    f.inputs "SEO" do
      f.input :meta_title
      f.input :meta_description
    end

    f.actions
  end

  controller do
    def create
      extract_uploaded_images
      super
      attach_images
    end

    def update
      extract_uploaded_images
      super
      attach_images
    end

    private

    def extract_uploaded_images
      @uploaded_images = Array(params.dig(:product, :images)).compact_blank
      params[:product].delete(:images) if params[:product]
    end

    def attach_images
      return if resource.errors.any? || @uploaded_images.blank?

      resource.images.attach(@uploaded_images)
    end
  end
end
