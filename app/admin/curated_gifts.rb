ActiveAdmin.register CuratedGift do
  extend SearchableAdmin

  menu parent: "Catalogue", priority: 4, label: "Curated gifts"
  searchable placeholder: "Search name, title, or description"

  permit_params :name, :product_title, :subtitle, :slug, :price, :compare_at_price,
                :discount_percent, :description, :status, :position, images: []

  config.sort_order = "position_asc"

  index do
    selectable_column
    id_column
    column("Image") do |gift|
      if gift.images.attached?
        image_tag gift.display_image, width: 50, height: 50, style: "object-fit:cover;border-radius:4px;"
      else
        "—"
      end
    end
    column :name
    column :product_title
    column :subtitle
    column("Price") { |gift| "₹#{gift.price}" }
    column("Discount") { |gift| gift.on_sale? ? "#{gift.discount_label} off (was ₹#{gift.compare_at_price})" : "—" }
    column :status
    column :position
    actions
  end

  filter :name
  filter :product_title
  filter :subtitle
  filter :status
  filter :price

  show do
    attributes_table do
      row :name
      row :product_title
      row :subtitle
      row :slug
      row(:price) { |gift| "₹#{gift.price}" }
      row(:compare_at_price) { |gift| gift.compare_at_price.present? ? "₹#{gift.compare_at_price}" : "—" }
      row("Discount") { |gift| gift.on_sale? ? "#{gift.discount_label} off" : "—" }
      row :status
      row :position
      row :description
      row :created_at
      row :updated_at
    end

    panel "Pictures" do
      if resource.images.attached?
        div style: "display:flex;gap:1.25rem;flex-wrap:wrap;padding:0.5rem 0;" do
          resource.images.each do |image|
            div style: "text-align:center;background:#fafafa;padding:8px;border-radius:8px;border:1px solid #eaeaea;" do
              image_tag image, width: 140, height: 140, style: "object-fit:cover;border-radius:6px;"
            end
          end
        end
      else
        para "No images attached yet."
      end
    end
  end

  form do |f|
    f.semantic_errors
    f.inputs "Curated Gift Option" do
      f.input :name, label: "Internal / Drop name", hint: "e.g. Treasure Drop — Little Finds"
      f.input :product_title, label: "Product title", hint: "e.g. Little Finds | Mystery Jewellery | ₹499"
      f.input :subtitle, label: "Subtitle / Tagline", hint: "e.g. Little Finds, The Charm Edit, The Statement Edit, The Signature Edit, The Muse Edit"
      f.input :slug, hint: "Leave blank to generate automatically from the name."
      f.input :price, label: "Price (₹)", hint: "The selling price customers pay."
      f.input :compare_at_price, label: "Marked price / Price before discount (₹)",
                      hint: "Optional. Struck through when higher than the selling price."
      f.input :discount_percent, label: "Discount %",
                      hint: "Auto-calculated when marked price is set, or type a discount percent."
      f.input :status, include_blank: false
      f.input :position, hint: "Display order on the storefront (lower numbers appear first)."
      f.input :description, as: :text, input_html: { rows: 4 }
    end

    f.inputs "Pictures" do
      gift = f.object
      if gift.persisted? && gift.images.attached?
        div style: "margin-bottom:1rem;display:flex;gap:1rem;flex-wrap:wrap;padding:0.5rem 0;" do
          gift.images.each do |img|
            span style: "display:inline-block;text-align:center;background:#fafafa;padding:6px;border-radius:6px;border:1px solid #eaeaea;" do
              image_tag(img, width: 90, height: 90, style: "object-fit:cover;border-radius:4px;") +
                br +
                link_to("Delete", delete_image_admin_curated_gift_path(gift, image_id: img.id),
                        method: :delete, data: { confirm: "Remove this picture?" },
                        style: "color:#dc2626;font-size:12px;margin-top:4px;display:inline-block;")
            end
          end
        end
      end
      f.input :images, as: :file, input_html: { multiple: true, accept: "image/*" },
                       hint: "JPEG, PNG, or WebP. New uploads are added to existing pictures."
    end

    f.actions
  end

  member_action :delete_image, method: :delete do
    image = resource.images.find(params[:image_id])
    image.purge
    redirect_to edit_admin_curated_gift_path(resource), notice: "Picture was successfully removed."
  end

  controller do
    def create
      extract_uploaded_images
      super do |success, _failure|
        success.html do
          attach_uploaded_images
          redirect_to admin_curated_gift_path(resource), notice: "Curated gift was successfully created."
        end
      end
    end

    def update
      extract_uploaded_images
      super do |success, _failure|
        success.html do
          attach_uploaded_images
          redirect_to admin_curated_gift_path(resource), notice: "Curated gift was successfully updated."
        end
      end
    end

    private

    def extract_uploaded_images
      @uploaded_images = Array(params.dig(:curated_gift, :images)).compact_blank
      params[:curated_gift].delete(:images) if params[:curated_gift]
    end

    def attach_uploaded_images
      return if @uploaded_images.blank? || !resource.persisted?

      resource.images.attach(@uploaded_images)
    end
  end
end
