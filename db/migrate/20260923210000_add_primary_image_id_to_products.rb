class AddPrimaryImageIdToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :primary_image_id, :bigint
    add_index :products, :primary_image_id
  end
end
