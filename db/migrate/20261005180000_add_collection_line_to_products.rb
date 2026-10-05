class AddCollectionLineToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :collection_line, :integer, null: false, default: 0
    add_index :products, :collection_line
  end
end
