class CreateDensheDomain < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :categories, :slug, unique: true
    add_index :categories, :position

    create_table :products do |t|
      t.references :category, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.string :sku
      t.text :description
      t.text :short_description
      t.decimal :purchase_price, precision: 10, scale: 2, null: false, default: 0
      t.decimal :selling_price, precision: 10, scale: 2, null: false
      t.decimal :compare_at_price, precision: 10, scale: 2
      t.decimal :packaging_allocation, precision: 10, scale: 2, null: false, default: 0
      t.decimal :shipping_allocation, precision: 10, scale: 2, null: false, default: 0
      t.decimal :gst_rate, precision: 5, scale: 2
      t.integer :quantity_purchased, null: false, default: 0
      t.integer :stock_quantity, null: false, default: 0
      t.integer :low_stock_threshold, null: false, default: 2
      t.string :material
      t.string :colour
      t.string :dimensions
      t.string :weight
      t.text :care_instructions
      t.text :whats_included
      t.integer :status, null: false, default: 0
      t.boolean :featured, null: false, default: false
      t.boolean :new_arrival, null: false, default: false
      t.boolean :bestseller, null: false, default: false
      t.string :meta_title
      t.text :meta_description
      t.timestamps
    end
    add_index :products, :slug, unique: true
    add_index :products, :sku, unique: true
    add_index :products, :status
    add_index :products, :featured

    create_table :customers do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      t.timestamps
    end
    add_index :customers, :email
    add_index :customers, :phone

    create_table :addresses do |t|
      t.references :customer, foreign_key: true
      t.string :name
      t.string :phone
      t.string :line1, null: false
      t.string :line2
      t.string :city, null: false
      t.string :state, null: false
      t.string :pin_code, null: false
      t.string :country, null: false, default: "India"
      t.integer :kind, null: false, default: 0
      t.timestamps
    end

    create_table :orders do |t|
      t.string :number
      t.references :customer, foreign_key: true
      t.references :shipping_address, foreign_key: { to_table: :addresses }
      t.references :billing_address, foreign_key: { to_table: :addresses }
      t.integer :order_type, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.decimal :subtotal, precision: 10, scale: 2, null: false, default: 0
      t.decimal :shipping_amount, precision: 10, scale: 2, null: false, default: 0
      t.decimal :discount, precision: 10, scale: 2, null: false, default: 0
      t.decimal :total, precision: 10, scale: 2, null: false, default: 0
      t.integer :payment_status, null: false, default: 0
      t.string :payment_reference
      t.string :payment_method
      t.integer :shipping_status, null: false, default: 0
      t.string :guest_name
      t.string :guest_email
      t.string :guest_phone
      t.text :customer_notes
      t.text :admin_notes
      t.timestamps
    end
    add_index :orders, :number, unique: true
    add_index :orders, :status
    add_index :orders, :payment_status
    add_index :orders, :order_type

    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, foreign_key: true
      t.integer :item_type, null: false, default: 0
      t.string :name, null: false
      t.string :sku
      t.integer :quantity, null: false, default: 1
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.timestamps
    end

    create_table :inventory_movements do |t|
      t.references :product, null: false, foreign_key: true
      t.references :admin_user, foreign_key: true
      t.references :order, foreign_key: true
      t.integer :quantity, null: false
      t.integer :movement_type, null: false
      t.string :reason
      t.timestamps
    end
    add_index :inventory_movements, :movement_type
    add_index :inventory_movements, :created_at

    create_table :mystery_box_preferences do |t|
      t.references :order, null: false, foreign_key: true, index: { unique: true }
      t.integer :recipient_type, null: false
      t.integer :jewellery_personality
      t.string :preferred_categories, array: true, default: []
      t.integer :style_preference
      t.integer :jewellery_amount
      t.string :preferred_finishes, array: true, default: []
      t.integer :occasion
      t.text :personal_message
      t.boolean :add_gift_note, null: false, default: false
      t.text :gift_note
      t.integer :piece_count_min, null: false, default: 3
      t.integer :piece_count_max, null: false, default: 5
      t.decimal :box_price, precision: 10, scale: 2, null: false, default: 599
      t.timestamps
    end
  end
end
