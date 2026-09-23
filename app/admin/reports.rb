# frozen_string_literal: true

ActiveAdmin.register_page "Reports" do
  menu priority: 2, label: "Reports"

  content title: "Category reports" do
    report = InventoryReport.new(params)
    totals = report.totals

    panel "Filters" do
      render "admin/reports/filters", report: report
    end

    panel report.summary_title do
      ul do
        li "Designs: #{totals[:designs]}"
        li "Pieces in stock: #{totals[:pieces]}"
        li "Purchase spend: ₹#{totals[:purchase_total]}"
      end
    end

    panel "Investors" do
      total_invested = Investment.sum(:amount)
      table_for Investor.order(:name) do
        column(:name) { |investor| link_to investor.name, admin_investor_path(investor) }
        column("Invested") { |investor| "₹#{investor.total_invested}" }
        column("Share") { |investor| "#{investor.share_percent(total_invested)}%" }
      end
      para "Right now Neshma has paid for all product lots and related purchase expenses. Devanshi’s share is ₹0 until she adds capital."
    end

    panel "Category wise" do
      summaries = report.category_summaries
      if summaries.any?
        table_for summaries do
          column(:category) do |row|
            link_to row[:name], admin_reports_path(report.filter_params.merge(category_id: row[:category_id]))
          end
          column("Designs") { |row| row[:designs] }
          column("Pieces") { |row| row[:pieces] }
          column("Purchase spend") { |row| "₹#{row[:purchase_total]}" }
        end
      else
        para "No products match these filters."
      end
    end

    panel "Pieces" do
      products = report.products
      if products.any?
        table_for products do
          column(:name) { |product| link_to product.name, admin_product_path(product) }
          column(:sku)
          column(:category)
          column(:supplier)
          column("Purchase") { |product| "₹#{product.purchase_price}" }
          column(:stock_quantity)
          column(:status)
        end
      else
        para "No pieces to list."
      end
    end
  end
end
