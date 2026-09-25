ActiveAdmin.register Product do
  extend SearchableAdmin

  menu parent: "Catalogue", priority: 2
  searchable placeholder: "Search name, SKU, or slug", index_includes: [ :category, :supplier ]

  permit_params :category_id, :supplier_id, :purchase_id, :name, :slug, :sku, :description, :short_description,
                :purchase_price, :selling_price, :compare_at_price, :packaging_allocation,
                :shipping_allocation, :gst_rate, :quantity_purchased, :stock_quantity,
                :low_stock_threshold, :material, :colour, :dimensions, :weight,
                :care_instructions, :whats_included, :status, :featured, :new_arrival,
                :bestseller, :meta_title, :meta_description, :primary_image_id,
                images: [], remove_image_ids: []

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
    column("Image") do |product|
      helpers.admin_thumb_tag(product.primary_image, 48,
                              width: 48, height: 48,
                              style: "object-fit:cover;border-radius:4px;")
    end
    column :name
    column :sku
    column :slug
    column :supplier
    column :category
    column :status
    column("Purchase") { |product| "₹#{product.purchase_price}" }
    column("Selling") { |product| "₹#{product.selling_price}" }
    column("Stock", &:stock_quantity)
    column("Purchased", &:quantity_purchased)
    column("Sold") { |product| sold_quantities[product.id].to_i }
    actions
  end

  filter :supplier
  filter :purchase
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
      row :supplier
      row :purchase
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

    panel "Designs" do
      if resource.images.attached?
        table_for resource.images.attachments do
          column("Preview") { |image| helpers.admin_thumb_tag(image, 180, width: 180) }
          column("File", &:filename)
          column("Storefront") do |image|
            if resource.primary_image?(image)
              status_tag "Primary"
            else
              button_to "Make primary", set_primary_image_admin_product_path(resource, image_id: image.id), method: :patch
            end
          end
          column("Remove") do |image|
            button_to "Remove", remove_image_admin_product_path(resource, image_id: image.id),
                      method: :delete,
                      data: { turbo_confirm: "Remove this design from #{resource.name}?" }
          end
        end
        para "The primary design is what customers will see first on the storefront."
      else
        para "No designs uploaded yet."
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
      f.input :supplier
      f.input :purchase
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

    f.inputs "Designs" do
      product = f.object
      # ActiveAdmin evaluates this form block twice; render to the buffer only once.
      if product.persisted? && product.images.attached? && !product.instance_variable_get(:@_admin_designs_rendered)
        product.instance_variable_set(:@_admin_designs_rendered, true)
        text_node helpers.render("admin/products/image_manager", product: product)
      end
      f.input :images, as: :file, input_html: { multiple: true, accept: "image/*" },
                       hint: "JPEG, PNG, or WebP. New uploads are added to the existing designs. Mark one as primary for the storefront."
    end

    f.inputs "SEO" do
      f.input :meta_title
      f.input :meta_description
    end

    f.actions
  end

  controller do
    helper_method :sold_quantities

    # One grouped query for the whole page instead of a SUM per row.
    def sold_quantities
      @sold_quantities ||= InventoryMovement
                             .where(product_id: collection.map(&:id), movement_type: :customer_order)
                             .group(:product_id)
                             .sum("ABS(quantity)")
    end

    def create
      extract_uploaded_images
      super
      attach_images
      resource.ensure_primary_image! if resource.persisted?
    end

    def update
      extract_image_management
      extract_uploaded_images
      super
      attach_images
      apply_image_management
    end

    private

    def extract_uploaded_images
      @uploaded_images = Array(params.dig(:product, :images)).compact_blank
      params[:product].delete(:images) if params[:product]
    end

    def extract_image_management
      @remove_image_ids = Array(params.dig(:product, :remove_image_ids)).compact_blank
      @primary_image_id = params.dig(:product, :primary_image_id)
      return unless params[:product]

      params[:product].delete(:remove_image_ids)
      params[:product].delete(:primary_image_id)
    end

    def attach_images
      return if resource.errors.any? || @uploaded_images.blank?

      resource.images.attach(@uploaded_images)
    end

    def apply_image_management
      return if resource.errors.any?

      resource.remove_images!(@remove_image_ids)
      resource.set_primary_image!(@primary_image_id)
      resource.ensure_primary_image!
    end
  end

  member_action :remove_image, method: :delete do
    resource.remove_images!([ params[:image_id] ])
    resource.ensure_primary_image!
    redirect_to admin_product_path(resource), notice: "Design removed."
  end

  member_action :set_primary_image, method: :patch do
    resource.set_primary_image!(params[:image_id])
    redirect_to admin_product_path(resource), notice: "Primary design updated. This image will show first on the storefront."
  end
end
