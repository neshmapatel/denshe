ActiveAdmin.register InventoryMovement do
  menu parent: "Catalogue", label: "Inventory", priority: 3

  permit_params :product_id, :quantity, :movement_type, :reason

  config.sort_order = "created_at_desc"
  actions :all, except: [ :edit, :update, :destroy ]

  index do
    id_column
    column :created_at
    column :product
    column :movement_type
    column(:quantity) { |movement| movement.quantity.positive? ? "+#{movement.quantity}" : movement.quantity }
    column :reason
    column :admin_user
    column :order
    actions
  end

  filter :product
  filter :movement_type
  filter :admin_user
  filter :created_at

  show do
    attributes_table do
      row :id
      row :product
      row :movement_type
      row :quantity
      row :reason
      row :admin_user
      row :order
      row :created_at
    end
  end

  form title: "Record stock movement" do |f|
    f.semantic_errors
    f.inputs do
      f.input :product
      f.input :movement_type, as: :select, collection: InventoryMovement.movement_types.keys
      f.input :quantity, hint: "Positive adds stock (purchase, return). Negative reduces stock (sale, damage, exhibition)."
      f.input :reason
    end
    f.actions
  end

  controller do
    def create
      product = Product.find(permitted_params.dig(:inventory_movement, :product_id))
      product.adjust_stock!(
        quantity: permitted_params.dig(:inventory_movement, :quantity),
        movement_type: permitted_params.dig(:inventory_movement, :movement_type),
        reason: permitted_params.dig(:inventory_movement, :reason),
        admin_user: current_admin_user
      )
      redirect_to admin_product_path(product), notice: "Stock updated for #{product.name}."
    rescue ArgumentError, ActiveRecord::RecordInvalid => error
      @inventory_movement = InventoryMovement.new(permitted_params[:inventory_movement])
      flash.now[:error] = error.message
      render :new, status: :unprocessable_entity
    end
  end
end
