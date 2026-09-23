# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: "Dashboard"

  content title: "DeNshe" do
    panel "Investors" do
      ul do
        Investor.order(:name).each do |investor|
          li "#{investor.name}: ₹#{investor.total_invested}"
        end
      end
    end

    panel "Sourcing" do
      ul do
        li "Suppliers: #{Supplier.count}"
        li "Purchase lots: #{Purchase.count}"
      end
    end

    panel "Catalogue" do
      ul do
        li "Total products: #{Product.count}"
        li "Active products: #{Product.active.count}"
        li "Draft products: #{Product.draft.count}"
        li "Low-stock products: #{Product.low_stock.count}"
        li "Out-of-stock products: #{Product.out_of_stock.count}"
        li { span link_to "Open category reports", admin_reports_path }
      end
    end

    panel "Orders" do
      ul do
        li "All orders: #{Order.count}"
        li "Paid orders: #{Order.revenue_paid.count}"
        li "Revenue (paid): ₹#{Order.revenue_paid.sum(:total)}"
        li "Mystery boxes: #{Order.mystery_box.count}"
      end
    end

    panel "Low stock" do
      products = Product.low_stock.includes(:category).order(:stock_quantity).limit(8)
      if products.any?
        table_for products do
          column(:product) { |product| link_to product.name, admin_product_path(product) }
          column(:stock, &:stock_quantity)
          column(:threshold, &:low_stock_threshold)
        end
      else
        para "No low-stock products right now."
      end
    end

    panel "Recent orders" do
      orders = Order.newest_first.limit(8)
      if orders.any?
        table_for orders do
          column(:number) { |order| link_to order.to_s, admin_order_path(order) }
          column(:customer, &:customer_display_name)
          column(:status) { |order| status_tag order.status }
          column(:total) { |order| "₹#{order.total}" }
        end
      else
        para "No orders yet. Checkout lands in Phase 3."
      end
    end

    panel "Recent products" do
      products = Product.includes(:category).order(created_at: :desc).limit(8)
      if products.any?
        table_for products do
          column(:name) { |product| link_to product.name, admin_product_path(product) }
          column(:supplier)
          column(:category)
          column(:status) { |product| status_tag product.status }
          column("Purchase") { |product| "₹#{product.purchase_price}" }
          column("Selling") { |product| "₹#{product.selling_price}" }
          column(:stock, &:stock_quantity)
        end
      else
        para do
          text_node "No products yet. "
          span link_to "Create the first piece", new_admin_product_path
        end
      end
    end
  end
end
