class CreateSuppliersAndPurchases < ActiveRecord::Migration[8.1]
  def change
    create_table :suppliers do |t|
      t.string :name, null: false
      t.string :phone
      t.string :area
      t.string :city
      t.string :state
      t.string :pin_code
      t.text :notes
      t.timestamps
    end
    add_index :suppliers, :name, unique: true

    create_table :purchases do |t|
      t.references :supplier, null: false, foreign_key: true
      t.string :reference, null: false
      t.date :purchased_on
      t.integer :article_count, null: false, default: 0
      t.decimal :merchandise_total, precision: 10, scale: 2, null: false, default: 0
      t.decimal :courier_charge, precision: 10, scale: 2, null: false, default: 0
      t.decimal :total_amount, precision: 10, scale: 2, null: false, default: 0
      t.text :notes
      t.timestamps
    end
    add_index :purchases, :reference, unique: true

    add_reference :products, :supplier, foreign_key: true
    add_reference :products, :purchase, foreign_key: true
  end
end
