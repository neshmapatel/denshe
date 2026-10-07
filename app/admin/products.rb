ActiveAdmin.register Product do
  extend SearchableAdmin

  menu parent: "Catalogue", priority: 2
  searchable placeholder: "Search name, SKU, or slug"

  permit_params :category_id, :supplier_id, :purchase_id, :name, :slug, :sku, :description, :short_description,
                :purchase_price, :selling_price, :compare_at_price, :discount_percent, :pricing_driver,
                :visible_in_australia, :selling_price_aud, :compare_at_price_aud, :discount_percent_aud,
                :pricing_driver_aud, :packaging_allocation,
                :shipping_allocation, :gst_rate, :quantity_purchased, :stock_quantity,
                :low_stock_threshold, :material, :colour, :dimensions, :weight,
                :care_instructions, :whats_included, :status, :collection_line, :featured, :new_arrival,
                :bestseller, :meta_title, :meta_description, :primary_image_id,
                images: [], remove_image_ids: [], clips: [], remove_clip_ids: []

  scope :all, default: true
  scope :earrings
  scope :western
  scope :indian
  scope :active
  scope :draft
  scope :archived
  scope :low_stock
  scope :out_of_stock
  scope :visible_in_australia
  scope("India only") { |products| products.where(visible_in_australia: false) }

  index title: -> { params[:search].present? ? "Products matching “#{params[:search]}”" : "Products" } do
    selectable_column
    id_column
    column("Image") do |product|
      if (image = product.primary_image)
        fullscreen_button image, alt: product.name, width: 48, height: 48,
                           style: "object-fit:cover;border-radius:4px;"
      end
    end
    column :name
    column :sku
    column :slug
    column :supplier
    column :category
    column("Line") { |product| product.collection_line_label }
    column :status
    column("Purchase") { |product| "₹#{product.purchase_price}" }
    column("Selling") { |product| "₹#{product.selling_price}" }
    column("Discount") { |product| product.discount_percent.to_d.positive? ? product.discount_label : "—" }
    column("Australia") do |product|
      product.offered_in?(Market.australia) ? "A$#{product.selling_price_aud}" : "—"
    end
    column("Stock", &:stock_quantity)
    column("Purchased", &:quantity_purchased)
    column("Sold", &:sold_quantity)
    actions defaults: true do |product|
      item "Restock", restock_admin_product_path(product)
    end
  end

  action_item :restock, only: :show do
    link_to "Restock", restock_admin_product_path(resource)
  end

  filter :supplier
  filter :purchase
  filter :category
  filter :collection_line, as: :select, collection: Product.collection_lines.keys.map { |key| [ key.titleize, key ] }
  filter :status
  filter :featured
  filter :new_arrival
  filter :bestseller
  filter :visible_in_australia

  show do
    attributes_table do
      row :name
      row :slug
      row :sku
      row :supplier
      row :purchase
      row :category
      row("Collection line") { |product| product.collection_line_record.name }
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
        row("Marked price") { |product| product.compare_at_price ? "₹#{product.compare_at_price}" : "—" }
        row("Discount") { |product| product.discount_label }
        row(:selling_price) { |product| "₹#{product.selling_price}" }
        row(:gst_rate) { |product| product.gst_rate.present? ? "#{product.gst_rate}%" : "Not set" }
        row(:contribution_margin) { |product| "₹#{product.contribution_margin}" }
        row(:visible_in_australia) { |product| product.visible_in_australia? ? "Yes" : "No" }
        row("Marked price (AUD)") { |product| product.compare_at_price_aud.present? ? "A$#{product.compare_at_price_aud}" : "—" }
        row("Discount (AUD)") { |product| Product.format_percent(product.discount_percent_aud) }
        row(:selling_price_aud) { |product| product.selling_price_aud.present? ? "A$#{product.selling_price_aud}" : "—" }
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
        span link_to "Restock", restock_admin_product_path(resource), class: "button"
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
          column("Preview") { |image| fullscreen_button image, alt: resource.name, width: 180, style: "width:180px;height:auto;object-fit:cover;" }
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

    panel "Clips" do
      if resource.clips.attached?
        resource.clips.each do |clip|
          div do
            text_node video_tag(rails_blob_path(clip), controls: true, playsinline: true, preload: "metadata", style: "width:280px;max-width:100%;")
          end
          para clip.filename.to_s
          div do
            button_to "Remove", remove_clip_admin_product_path(resource, clip_id: clip.id),
                      method: :delete,
                      data: { turbo_confirm: "Remove this clip from #{resource.name}?" }
          end
        end
        para "Short clips play beside the photographs on the piece page."
      else
        para "No clips uploaded yet."
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

  form html: { multipart: true, data: { turbo: false } } do |f|
    f.semantic_errors
    f.inputs "Basic" do
      f.input :category
      f.input :collection_line, as: :select,
              collection: Product.collection_lines.keys.map { |key|
                [ CollectionLine.find(key).name, key ]
              },
              include_blank: false,
              hint: "The Modern Edit is everyday wear. The Festive Edit is the festive cabinet, and it stays a waiting page until one of its pieces is active."
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

    f.inputs "Pricing", data: { pricing_group: "in" } do
      f.input :purchase_price, label: "Purchase price (what DeNshe paid)"
      f.input :packaging_allocation
      f.input :shipping_allocation
      f.input :compare_at_price, label: "Marked price",
              hint: "The price before discount, such as 339. Customers see it struck through when it is higher than the selling price.",
              input_html: { data: { pricing_role: "marked", pricing_group: "in" } }
      f.input :discount_percent, label: "Discount %",
              hint: "Percent off the marked price. 20 on 339 sets the selling price to 271.20.",
              input_html: { min: 0, max: 100, step: 0.01, data: { pricing_role: "percent", pricing_group: "in" } }
      f.input :selling_price,
              hint: "What the customer pays. Type a selling price and the discount percent fills in from the marked price.",
              input_html: { data: { pricing_role: "selling", pricing_group: "in" } }
      f.input :pricing_driver, as: :hidden, input_html: { value: "", data: { pricing_role: "driver", pricing_group: "in" } }
      text_node helpers.tag.li(class: "input") {
        helpers.tag.p(
          Product.discount_summary(f.object.compare_at_price, f.object.discount_percent, f.object.selling_price, "₹"),
          class: "inline-hints",
          data: { pricing_preview: "in", pricing_currency: "₹" }
        )
      }
      f.input :gst_rate, hint: "Optional percent, e.g. 3 or 18. Leave blank for now."
    end

    f.inputs "Australia", data: { pricing_group: "au" } do
      f.input :visible_in_australia, label: "Visible in Australia",
              hint: "Turn this on to list the piece for shoppers in Australia. Leave it off to keep the piece in the India shop only."
      f.input :compare_at_price_aud, label: "Marked price (AUD)",
              hint: "The Australian price before discount. The shop strikes it through when it is higher than the selling price.",
              input_html: { data: { pricing_role: "marked", pricing_group: "au" } }
      f.input :discount_percent_aud, label: "Discount % (AUD)",
              hint: "Percent off the Australian marked price. The selling price fills in from it.",
              input_html: { min: 0, max: 100, step: 0.01, data: { pricing_role: "percent", pricing_group: "au" } }
      f.input :selling_price_aud, label: "Selling price (AUD)",
              hint: "Required when the piece is visible in Australia. Type a selling price to see the discount percent instead.",
              input_html: { data: { pricing_role: "selling", pricing_group: "au" } }
      f.input :pricing_driver_aud, as: :hidden, input_html: { value: "", data: { pricing_role: "driver", pricing_group: "au" } }
      text_node helpers.tag.li(class: "input") {
        helpers.tag.p(
          Product.discount_summary(f.object.compare_at_price_aud, f.object.discount_percent_aud, f.object.selling_price_aud, "A$"),
          class: "inline-hints",
          data: { pricing_preview: "au", pricing_currency: "A$" }
        )
      }
    end

    unless f.object.instance_variable_get(:@_discount_script)
      f.object.instance_variable_set(:@_discount_script, true)
      text_node helpers.render("admin/products/discount_pricing")
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

    f.inputs "Clips" do
      product = f.object
      if product.persisted? && product.clips.attached? && !product.instance_variable_get(:@_admin_clips_rendered)
        product.instance_variable_set(:@_admin_clips_rendered, true)
        text_node helpers.render("admin/products/clip_manager", product: product)
      end
      f.input :clips, as: :file, input_html: { multiple: true, accept: "video/mp4,video/quicktime,video/webm,.mp4,.mov,.webm" },
                      hint: "Short clips only. MP4, MOV, or WebM, up to 25 MB each. A piece can keep three."
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
      extract_uploaded_clips
      super do |success, _failure|
        success.html { redirect_after_images(:created) }
      end
    rescue ActiveRecord::RecordNotUnique
      flag_duplicate_product
      render :new, status: :unprocessable_entity
    end

    def update
      extract_image_management
      extract_uploaded_images
      extract_uploaded_clips
      super do |success, _failure|
        success.html { redirect_after_images(:updated) }
      end
    rescue ActiveRecord::RecordNotUnique
      flag_duplicate_product
      render :edit, status: :unprocessable_entity
    end

    private

    def extract_uploaded_images
      @uploaded_images = Array(params.dig(:product, :images)).compact_blank
      params[:product].delete(:images) if params[:product]
    end

    def extract_uploaded_clips
      @uploaded_clips = Array(params.dig(:product, :clips)).compact_blank
      params[:product].delete(:clips) if params[:product]
    end

    def extract_image_management
      @remove_image_ids = Array(params.dig(:product, :remove_image_ids)).compact_blank
      @primary_image_id = params.dig(:product, :primary_image_id)
      return unless params[:product]

      params[:product].delete(:remove_image_ids)
      params[:product].delete(:primary_image_id)
      @remove_clip_ids = Array(params[:product].delete(:remove_clip_ids)).compact_blank
    end

    def attach_images
      return true if resource.errors.any? || @uploaded_images.blank? || !resource.persisted?

      resource.images.attach(@uploaded_images)
      resource.ensure_primary_image!
      true
    rescue StandardError => error
      raise unless storage_error?(error)

      Rails.logger.error("Product image upload failed: #{error.class}: #{error.message}")
      false
    end

    def storage_error?(error)
      error.class.name.start_with?("Aws::", "ActiveStorage::")
    end

    def redirect_after_images(action)
      notice = "Product was successfully #{action}."
      images_stored = attach_images
      changes_stored = apply_pending_image_changes
      problems = []
      problems << "The photo could not be stored. Please upload it again from this page." unless images_stored && changes_stored
      problems.concat(attach_clips)

      if problems.empty?
        redirect_to resource_path(resource), notice: notice
      else
        redirect_to edit_admin_product_path(resource), alert: "#{notice} #{problems.to_sentence}."
      end
    end

    def attach_clips
      return [] if resource.errors.any? || @uploaded_clips.blank? || !resource.persisted?

      resource.attach_clips!(@uploaded_clips)
    rescue StandardError => error
      raise unless storage_error?(error)

      Rails.logger.error("Product clip upload failed: #{error.class}: #{error.message}")
      [ "The clip could not be stored. Please upload it again from this page." ]
    end

    def apply_pending_image_changes
      return true unless action_name == "update"

      apply_image_management
      true
    rescue StandardError => error
      raise unless storage_error?(error)

      Rails.logger.error("Product image change failed: #{error.class}: #{error.message}")
      false
    end

    def flag_duplicate_product
      resource.errors.add(:base, "This product is already saved. Check the product list, or use a different SKU.")
    end

    def apply_image_management
      return if resource.errors.any?

      resource.remove_images!(@remove_image_ids)
      resource.remove_clips!(@remove_clip_ids)
      resource.set_primary_image!(@primary_image_id)
      resource.ensure_primary_image!
    end
  end

  member_action :remove_image, method: :delete do
    resource.remove_images!([ params[:image_id] ])
    resource.ensure_primary_image!
    redirect_to admin_product_path(resource), notice: "Design removed."
  end

  member_action :remove_clip, method: :delete do
    resource.remove_clips!([ params[:clip_id] ])
    redirect_to admin_product_path(resource), notice: "Clip removed."
  end

  member_action :set_primary_image, method: :patch do
    resource.set_primary_image!(params[:image_id])
    redirect_to admin_product_path(resource), notice: "Primary design updated. This image will show first on the storefront."
  end

  member_action :restock, method: :get do
    @page_title = "Restock #{resource.name}"
  end

  member_action :apply_restock, method: :post do
    quantity = params.dig(:restock, :quantity).to_i
    reason = params.dig(:restock, :reason).to_s.strip
    reason = "Restock" if reason.blank?

    if quantity <= 0
      redirect_to restock_admin_product_path(resource), alert: "Enter how many pieces arrived."
      return
    end

    resource.adjust_stock!(
      quantity: quantity,
      movement_type: :purchase,
      reason: reason,
      admin_user: current_admin_user
    )

    redirect_to admin_product_path(resource),
                notice: "Added #{quantity} #{'piece'.pluralize(quantity)}. Stock is now #{resource.reload.stock_quantity}."
  rescue ArgumentError, ActiveRecord::RecordInvalid => error
    redirect_to restock_admin_product_path(resource), alert: error.message
  end
end
