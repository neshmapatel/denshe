class AddDisplayStockLeftToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :display_stock_left, :integer, default: nil
    add_index :products, :display_stock_left
  end
end
