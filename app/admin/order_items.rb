ActiveAdmin.register OrderItem do
  menu false

  permit_params :order_id, :product_id, :item_type, :name, :sku, :quantity, :unit_price
end
