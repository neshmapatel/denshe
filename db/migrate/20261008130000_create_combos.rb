class CreateCombos < ActiveRecord::Migration[8.1]
  def change
    create_table :combos do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :short_description
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :combos, :slug, unique: true
    add_index :combos, :status

    create_table :combo_groups do |t|
      t.references :combo, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :choose_count, null: false, default: 1
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    create_table :combo_options do |t|
      t.references :combo_group, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :combo_options, [ :combo_group_id, :product_id ], unique: true
  end
end
