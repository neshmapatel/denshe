class CreateCartHolds < ActiveRecord::Migration[8.1]
  def change
    create_table :cart_holds do |t|
      t.string :session_key, null: false
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.timestamps
    end

    add_index :cart_holds, [ :session_key, :product_id ], unique: true
    add_index :cart_holds, :updated_at
  end
end