# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_07_163000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.bigint "author_id"
    t.string "author_type"
    t.text "body"
    t.datetime "created_at", null: false
    t.string "namespace"
    t.bigint "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", force: :cascade do |t|
    t.string "city", null: false
    t.string "country", default: "India", null: false
    t.datetime "created_at", null: false
    t.bigint "customer_id"
    t.integer "kind", default: 0, null: false
    t.string "line1", null: false
    t.string "line2"
    t.string "name"
    t.string "phone"
    t.string "pin_code", null: false
    t.string "state", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_addresses_on_customer_id"
  end

  create_table "admin_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_categories_on_position"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "customers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_customers_on_email"
    t.index ["phone"], name: "index_customers_on_phone"
  end

  create_table "inventory_movements", force: :cascade do |t|
    t.bigint "admin_user_id"
    t.datetime "created_at", null: false
    t.integer "movement_type", null: false
    t.bigint "order_id"
    t.bigint "product_id", null: false
    t.integer "quantity", null: false
    t.string "reason"
    t.datetime "updated_at", null: false
    t.index ["admin_user_id"], name: "index_inventory_movements_on_admin_user_id"
    t.index ["created_at"], name: "index_inventory_movements_on_created_at"
    t.index ["movement_type"], name: "index_inventory_movements_on_movement_type"
    t.index ["order_id"], name: "index_inventory_movements_on_order_id"
    t.index ["product_id"], name: "index_inventory_movements_on_product_id"
  end

  create_table "mystery_box_preferences", force: :cascade do |t|
    t.boolean "add_gift_note", default: false, null: false
    t.decimal "box_price", precision: 10, scale: 2, default: "599.0", null: false
    t.datetime "created_at", null: false
    t.text "gift_note"
    t.integer "jewellery_amount"
    t.integer "jewellery_personality"
    t.integer "occasion"
    t.bigint "order_id", null: false
    t.text "personal_message"
    t.integer "piece_count_max", default: 5, null: false
    t.integer "piece_count_min", default: 3, null: false
    t.string "preferred_categories", default: [], array: true
    t.string "preferred_finishes", default: [], array: true
    t.integer "recipient_type", null: false
    t.integer "style_preference"
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_mystery_box_preferences_on_order_id", unique: true
  end

  create_table "order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "item_type", default: 0, null: false
    t.string "name", null: false
    t.bigint "order_id", null: false
    t.bigint "product_id"
    t.integer "quantity", default: 1, null: false
    t.string "sku"
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.text "admin_notes"
    t.bigint "billing_address_id"
    t.datetime "created_at", null: false
    t.bigint "customer_id"
    t.text "customer_notes"
    t.decimal "discount", precision: 10, scale: 2, default: "0.0", null: false
    t.string "guest_email"
    t.string "guest_name"
    t.string "guest_phone"
    t.string "number"
    t.integer "order_type", default: 0, null: false
    t.string "payment_method"
    t.string "payment_reference"
    t.integer "payment_status", default: 0, null: false
    t.bigint "shipping_address_id"
    t.decimal "shipping_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "shipping_status", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.decimal "subtotal", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "total", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["billing_address_id"], name: "index_orders_on_billing_address_id"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["number"], name: "index_orders_on_number", unique: true
    t.index ["order_type"], name: "index_orders_on_order_type"
    t.index ["payment_status"], name: "index_orders_on_payment_status"
    t.index ["shipping_address_id"], name: "index_orders_on_shipping_address_id"
    t.index ["status"], name: "index_orders_on_status"
  end

  create_table "products", force: :cascade do |t|
    t.boolean "bestseller", default: false, null: false
    t.text "care_instructions"
    t.bigint "category_id", null: false
    t.string "colour"
    t.decimal "compare_at_price", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.text "description"
    t.string "dimensions"
    t.boolean "featured", default: false, null: false
    t.decimal "gst_rate", precision: 5, scale: 2
    t.integer "low_stock_threshold", default: 2, null: false
    t.string "material"
    t.text "meta_description"
    t.string "meta_title"
    t.string "name", null: false
    t.boolean "new_arrival", default: false, null: false
    t.decimal "packaging_allocation", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "purchase_price", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "quantity_purchased", default: 0, null: false
    t.decimal "selling_price", precision: 10, scale: 2, null: false
    t.decimal "shipping_allocation", precision: 10, scale: 2, default: "0.0", null: false
    t.text "short_description"
    t.string "sku"
    t.string "slug", null: false
    t.integer "status", default: 0, null: false
    t.integer "stock_quantity", default: 0, null: false
    t.datetime "updated_at", null: false
    t.string "weight"
    t.text "whats_included"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["featured"], name: "index_products_on_featured"
    t.index ["sku"], name: "index_products_on_sku", unique: true
    t.index ["slug"], name: "index_products_on_slug", unique: true
    t.index ["status"], name: "index_products_on_status"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "addresses", "customers"
  add_foreign_key "inventory_movements", "admin_users"
  add_foreign_key "inventory_movements", "orders"
  add_foreign_key "inventory_movements", "products"
  add_foreign_key "mystery_box_preferences", "orders"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "addresses", column: "billing_address_id"
  add_foreign_key "orders", "addresses", column: "shipping_address_id"
  add_foreign_key "orders", "customers"
  add_foreign_key "products", "categories"
end
